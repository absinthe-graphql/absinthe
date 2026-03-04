defmodule Absinthe.Incremental.Dataloader do
  @moduledoc """
  Dataloader integration for incremental delivery.

  This module ensures that batching continues to work efficiently even when
  fields are deferred or streamed. It groups deferred/streamed fields by their
  batch keys and resolves them together to maintain the benefits of batching.

  ## Usage

  This module is used automatically when you have both Dataloader and incremental
  delivery enabled. No additional configuration is required for basic usage.

  ### Using with existing Dataloader resolvers

  Your existing Dataloader resolvers will continue to work. For optimal performance
  with incremental delivery, you can use the streaming-aware resolver:

      field :posts, list_of(:post) do
        resolve Absinthe.Incremental.Dataloader.streaming_dataloader(:db, :posts)
      end

  This ensures that deferred fields using the same batch key are resolved together,
  maintaining the N+1 prevention benefits of Dataloader even with @defer/@stream.

  ### Manual batch control

  For advanced use cases, you can manually prepare and resolve batches:

      # Get grouped batches from the blueprint
      batches = Absinthe.Incremental.Dataloader.prepare_streaming_batch(blueprint)

      # Resolve each batch
      for batch <- batches.deferred do
        results = Absinthe.Incremental.Dataloader.resolve_streaming_batch(batch, dataloader)
        # Process results...
      end

  ## How it works

  When a query contains @defer or @stream directives, this module:
  1. Groups deferred/streamed fields by their Dataloader batch keys
  2. Ensures fields with the same batch key are resolved together
  3. Maintains efficient batching even when fields are delivered incrementally
  """

  alias Absinthe.Resolution
  alias Absinthe.Blueprint

  @type batch_key :: {atom(), any()}
  @type batch_context :: %{
          source: atom(),
          batch_key: any(),
          fields: list(map()),
          ids: list(any())
        }

  @doc """
  Prepare batches for streaming operations.

  Groups deferred and streamed fields by their batch keys to ensure
  efficient resolution even with incremental delivery.
  """
  @spec prepare_streaming_batch(Blueprint.t()) :: %{
          deferred: list(batch_context()),
          streamed: list(batch_context())
        }
  def prepare_streaming_batch(blueprint) do
    streaming_context = get_streaming_context(blueprint)

    %{
      deferred: prepare_deferred_batches(streaming_context),
      streamed: prepare_streamed_batches(streaming_context)
    }
  end

  @doc """
  Resolve a batch of fields together for streaming.

  This ensures that even deferred/streamed fields benefit from
  Dataloader's batching capabilities.
  """
  @spec resolve_streaming_batch(batch_context(), Dataloader.t()) ::
          list({map(), any()})
  def resolve_streaming_batch(batch_context, dataloader) do
    # Load all the data for this batch
    dataloader =
      dataloader
      |> Dataloader.load_many(
        batch_context.source,
        batch_context.batch_key,
        batch_context.ids
      )
      |> Dataloader.run()

    # Extract results for each field
    Enum.map(batch_context.fields, fn field ->
      result =
        Dataloader.get(
          dataloader,
          batch_context.source,
          batch_context.batch_key,
          field.id
        )

      {field, result}
    end)
  end

  @doc """
  Create a Dataloader instance for streaming operations.

  This sets up a new Dataloader with appropriate configuration
  for incremental delivery.
  """
  @spec create_streaming_dataloader(Keyword.t()) :: Dataloader.t()
  def create_streaming_dataloader(opts \\ []) do
    sources = Keyword.get(opts, :sources, [])

    Enum.reduce(sources, Dataloader.new(), fn {name, source}, dataloader ->
      Dataloader.add_source(dataloader, name, source)
    end)
  end

  @doc """
  Wrap a resolver with Dataloader support for streaming.

  This allows existing Dataloader resolvers to work with incremental delivery.
  """
  @spec streaming_dataloader(atom(), any()) :: Resolution.resolver()
  def streaming_dataloader(source, batch_key \\ nil) do
    fn parent, args, %{context: context} = resolution ->
      # Check if we're in a streaming context
      case Map.get(context, :__streaming__) do
        nil ->
          # Standard dataloader resolution
          resolver = Resolution.Helpers.dataloader(source, batch_key)
          resolver.(parent, args, resolution)

        streaming_context ->
          # Streaming-aware resolution
          resolve_with_streaming_dataloader(
            source,
            batch_key,
            parent,
            args,
            resolution,
            streaming_context
          )
      end
    end
  end

  @doc """
  Batch multiple streaming operations together.

  This is used by the streaming resolution phase to group
  operations that can be batched.
  """
  @spec batch_streaming_operations(list(map())) :: list(list(map()))
  def batch_streaming_operations(operations) do
    operations
    |> Enum.group_by(&extract_batch_key/1)
    |> Map.values()
  end

  # Private functions

  defp prepare_deferred_batches(streaming_context) do
    deferred_fragments = Map.get(streaming_context, :deferred_fragments, [])

    deferred_fragments
    |> group_by_batch_key()
    |> Enum.map(&create_batch_context/1)
  end

  defp prepare_streamed_batches(streaming_context) do
    streamed_fields = Map.get(streaming_context, :streamed_fields, [])

    streamed_fields
    |> group_by_batch_key()
    |> Enum.map(&create_batch_context/1)
  end

  defp group_by_batch_key(nodes) do
    Enum.group_by(nodes, &extract_batch_key/1)
  end

  defp extract_batch_key(%{node: node}) do
    extract_batch_key(node)
  end

  defp extract_batch_key(node) do
    # Extract the batch key from the node's resolver configuration
    case get_resolver_info(node) do
      {:dataloader, source, batch_key} ->
        {source, batch_key}

      _ ->
        :no_batch
    end
  end

  defp get_resolver_info(node) do
    # Navigate the node structure to find resolver info
    case node do
      %{schema_node: %{resolver: resolver}} ->
        parse_resolver(resolver)

      %{resolver: resolver} ->
        parse_resolver(resolver)

      _ ->
        nil
    end
  end

  defp parse_resolver({:dataloader, source}), do: {:dataloader, source, nil}
  defp parse_resolver({:dataloader, source, batch_key}), do: {:dataloader, source, batch_key}
  defp parse_resolver(_), do: nil

  defp create_batch_context({batch_key, fields}) do
    {source, key} =
      case batch_key do
        {s, k} -> {s, k}
        :no_batch -> {nil, nil}
        s -> {s, nil}
      end

    ids =
      Enum.map(fields, fn field ->
        get_field_id(field)
      end)

    %{
      source: source,
      batch_key: key,
      fields: fields,
      ids: ids
    }
  end

  defp get_field_id(field) do
    # Extract the ID for batching from the field
    case field do
      %{node: %{argument_data: %{id: id}}} -> id
      %{node: %{source: %{id: id}}} -> id
      %{id: id} -> id
      _ -> nil
    end
  end

  defp resolve_with_streaming_dataloader(
         source,
         batch_key,
         parent,
         args,
         resolution,
         streaming_context
       ) do
    # Check if this is part of a deferred/streamed operation
    if in_streaming_operation?(resolution, streaming_context) do
      # Queue for batch resolution
      queue_for_batch(source, batch_key, parent, args, resolution)
    else
      # Regular dataloader resolution
      resolver = Resolution.Helpers.dataloader(source, batch_key)
      resolver.(parent, args, resolution)
    end
  end

  defp in_streaming_operation?(resolution, streaming_context) do
    # Check if the current resolution is part of a deferred/streamed operation
    path = Resolution.path(resolution)

    deferred_paths =
      Enum.map(
        streaming_context.deferred_fragments || [],
        & &1.path
      )

    streamed_paths =
      Enum.map(
        streaming_context.streamed_fields || [],
        & &1.path
      )

    Enum.any?(deferred_paths ++ streamed_paths, fn streaming_path ->
      path_matches?(path, streaming_path)
    end)
  end

  defp path_matches?(current_path, streaming_path) do
    # Check if the current path is under a streaming path
    List.starts_with?(current_path, streaming_path)
  end

  defp queue_for_batch(source, batch_key, parent, _args, resolution) do
    # Queue this resolution for batch processing
    batch_data = %{
      source: source,
      batch_key: batch_key || fn parent -> Map.get(parent, :id) end,
      parent: parent,
      resolution: resolution
    }

    # Add to the batch queue in the resolution context
    resolution =
      update_in(
        resolution.context[:__dataloader_batch_queue__],
        &[batch_data | &1 || []]
      )

    # Return a placeholder that will be resolved in batch
    {:middleware, Absinthe.Middleware.Dataloader, {source, batch_key}}
  end

  defp get_streaming_context(blueprint) do
    get_in(blueprint, [:execution, :context, :__streaming__]) || %{}
  end

  @doc """
  Process queued batch operations for streaming.

  This is called after the initial resolution to process
  any queued dataloader operations in batch.
  """
  @spec process_batch_queue(Resolution.t()) :: Resolution.t()
  def process_batch_queue(%{context: context} = resolution) do
    case Map.get(context, :__dataloader_batch_queue__) do
      nil ->
        resolution

      [] ->
        resolution

      queue ->
        # Group by source and batch key
        batches =
          queue
          |> Enum.group_by(fn %{source: s, batch_key: k} -> {s, k} end)

        # Process each batch
        dataloader = Map.get(context, :loader) || Dataloader.new()

        dataloader =
          Enum.reduce(batches, dataloader, fn {{source, batch_key}, items}, dl ->
            ids =
              Enum.map(items, fn %{parent: parent} ->
                case batch_key do
                  nil -> Map.get(parent, :id)
                  fun when is_function(fun) -> fun.(parent)
                  key -> Map.get(parent, key)
                end
              end)

            Dataloader.load_many(dl, source, batch_key, ids)
          end)
          |> Dataloader.run()

        # Update context with results
        context = Map.put(context, :loader, dataloader)
        %{resolution | context: context}
    end
  end
end
