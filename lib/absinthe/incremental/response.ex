defmodule Absinthe.Incremental.Response do
  @moduledoc """
  Builds incremental delivery responses according to the GraphQL incremental delivery specification.

  This module handles formatting of initial and incremental payloads for @defer and @stream directives.
  """

  alias Absinthe.Blueprint

  @type initial_response :: %{
          data: map(),
          pending: list(pending_item()),
          hasNext: boolean(),
          errors: list(map()) | nil
        }

  @type incremental_response :: %{
          incremental: list(incremental_item()),
          hasNext: boolean(),
          completed: list(completed_item()) | nil
        }

  @type pending_item :: %{
          id: String.t(),
          path: list(String.t() | integer()),
          label: String.t() | nil
        }

  @type incremental_item :: %{
          data: any(),
          path: list(String.t() | integer()),
          label: String.t() | nil,
          errors: list(map()) | nil
        }

  @type completed_item :: %{
          id: String.t(),
          errors: list(map()) | nil
        }

  @doc """
  Build the initial response for a query with incremental delivery.

  The initial response contains:
  - The immediately available data
  - A list of pending operations that will be delivered incrementally
  - A hasNext flag indicating more payloads are coming
  """
  @spec build_initial(Blueprint.t()) :: initial_response()
  def build_initial(blueprint) do
    streaming_context = get_streaming_context(blueprint)

    response = %{
      data: extract_initial_data(blueprint),
      pending: build_pending_list(streaming_context),
      hasNext: has_pending_operations?(streaming_context)
    }

    # Add errors if present
    case blueprint.result[:errors] do
      nil -> response
      [] -> response
      errors -> Map.put(response, :errors, errors)
    end
  end

  @doc """
  Build an incremental response for deferred or streamed data.

  Each incremental response contains:
  - The incremental data items
  - A hasNext flag indicating if more payloads are coming
  - Optional completed items to signal completion of specific operations
  """
  @spec build_incremental(any(), list(), String.t() | nil, boolean()) :: incremental_response()
  def build_incremental(data, path, label, has_next) do
    incremental_item = %{
      data: data,
      path: path
    }

    incremental_item =
      if label do
        Map.put(incremental_item, :label, label)
      else
        incremental_item
      end

    %{
      incremental: [incremental_item],
      hasNext: has_next
    }
  end

  @doc """
  Build an incremental response for streamed list items.
  """
  @spec build_stream_incremental(list(), list(), String.t() | nil, boolean()) ::
          incremental_response()
  def build_stream_incremental(items, path, label, has_next) do
    incremental_item = %{
      items: items,
      path: path
    }

    incremental_item =
      if label do
        Map.put(incremental_item, :label, label)
      else
        incremental_item
      end

    %{
      incremental: [incremental_item],
      hasNext: has_next
    }
  end

  @doc """
  Build a completion response to signal the end of incremental delivery.
  """
  @spec build_completed(list(String.t())) :: incremental_response()
  def build_completed(completed_ids) do
    completed_items =
      Enum.map(completed_ids, fn id ->
        %{id: id}
      end)

    %{
      completed: completed_items,
      hasNext: false
    }
  end

  @doc """
  Build an error response for a failed incremental operation.
  """
  @spec build_error(list(map()), list(), String.t() | nil, boolean()) :: incremental_response()
  def build_error(errors, path, label, has_next) do
    incremental_item = %{
      errors: errors,
      path: path
    }

    incremental_item =
      if label do
        Map.put(incremental_item, :label, label)
      else
        incremental_item
      end

    %{
      incremental: [incremental_item],
      hasNext: has_next
    }
  end

  # Private functions

  defp extract_initial_data(blueprint) do
    # Extract the data from the blueprint result
    # Skip any fields/fragments marked as deferred or streamed
    result = blueprint.result[:data] || %{}

    # If we have streaming context, we need to filter the data
    case get_streaming_context(blueprint) do
      nil ->
        result

      streaming_context ->
        filter_initial_data(result, streaming_context)
    end
  end

  defp filter_initial_data(data, streaming_context) do
    # Remove deferred fragments and limit streamed fields
    data
    |> filter_deferred_fragments(streaming_context.deferred_fragments)
    |> filter_streamed_fields(streaming_context.streamed_fields)
  end

  defp filter_deferred_fragments(data, deferred_fragments) do
    # Remove data for deferred fragments from initial response
    Enum.reduce(deferred_fragments, data, fn fragment, acc ->
      remove_at_path(acc, fragment.path)
    end)
  end

  defp filter_streamed_fields(data, streamed_fields) do
    # Limit streamed fields to initial_count items
    Enum.reduce(streamed_fields, data, fn field, acc ->
      limit_at_path(acc, field.path, field.initial_count)
    end)
  end

  defp remove_at_path(data, []), do: nil

  defp remove_at_path(data, [key | rest]) when is_map(data) do
    case Map.get(data, key) do
      nil -> data
      _value when rest == [] -> Map.delete(data, key)
      value -> Map.put(data, key, remove_at_path(value, rest))
    end
  end

  defp remove_at_path(data, _path), do: data

  defp limit_at_path(data, [], _limit), do: data

  defp limit_at_path(data, [key | rest], limit) when is_map(data) do
    case Map.get(data, key) do
      nil ->
        data

      value when rest == [] and is_list(value) ->
        Map.put(data, key, Enum.take(value, limit))

      value ->
        Map.put(data, key, limit_at_path(value, rest, limit))
    end
  end

  defp limit_at_path(data, _path, _limit), do: data

  defp build_pending_list(streaming_context) do
    deferred =
      Enum.map(streaming_context.deferred_fragments || [], fn fragment ->
        pending = %{
          id: generate_pending_id(),
          path: fragment.path
        }

        if fragment.label do
          Map.put(pending, :label, fragment.label)
        else
          pending
        end
      end)

    streamed =
      Enum.map(streaming_context.streamed_fields || [], fn field ->
        pending = %{
          id: generate_pending_id(),
          path: field.path
        }

        if field.label do
          Map.put(pending, :label, field.label)
        else
          pending
        end
      end)

    deferred ++ streamed
  end

  defp has_pending_operations?(streaming_context) do
    has_deferred = not Enum.empty?(streaming_context.deferred_fragments || [])
    has_streamed = not Enum.empty?(streaming_context.streamed_fields || [])

    has_deferred or has_streamed
  end

  defp get_streaming_context(blueprint) do
    get_in(blueprint, [:execution, :context, :__streaming__])
  end

  defp generate_pending_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
