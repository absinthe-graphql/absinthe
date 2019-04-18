defmodule Absinthe.Phase.Subscription.SubscribeSelf do
  use Absinthe.Phase
  alias Absinthe.Phase

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t()) :: {:ok, Blueprint.t()}
  def run(blueprint, options) do
    with %{type: :subscription} = op <- Blueprint.current_operation(blueprint) do
      do_subscription(op, blueprint, options)
    else
      _ -> {:ok, blueprint}
    end
  end

  def do_subscription(%{type: :subscription} = op, blueprint, options) do
    context = blueprint.execution.context
    pubsub = ensure_pubsub!(context)

    hash = :crypto.hash(:sha256, :erlang.term_to_binary(blueprint)) |> Base.encode16()
    doc_id = "__absinthe__:doc:#{hash}"

    %{selections: [field]} = op

    with {:ok, field_keys} <- get_field_keys(field, context) do
      for field_key <- field_keys,
          do: Absinthe.Subscription.subscribe(pubsub, field_key, doc_id, blueprint)

      {:replace, blueprint, [{Phase.Subscription.Result, topic: doc_id}]}
    else
      {:error, error} ->
        blueprint = update_in(blueprint.execution.validation_errors, &[error | &1])

        error_pipeline = [
          {Phase.Document.Result, options}
        ]

        {:replace, blueprint, error_pipeline}
    end
  end

  defp get_field_keys(%{schema_node: schema_node, argument_data: argument_data} = field, context) do
    name = schema_node.identifier

    config =
      case Absinthe.Type.function(schema_node, :config) do
        fun when is_function(fun, 2) ->
          apply(fun, [argument_data, %{context: context}])

        fun when is_function(fun, 1) ->
          IO.write(
            :stderr,
            "Warning: 1-arity topic functions are deprecated, upgrade to 2 arity before 1.4.0 release"
          )

          apply(fun, [argument_data])

        nil ->
          {:ok, topic: Atom.to_string(name)}
      end

    case config do
      {:ok, config} ->
        field_keys =
          find_keys!(config)
          |> Enum.map(fn key -> {name, key} end)

        {:ok, field_keys}

      {:error, msg} ->
        error = %Phase.Error{
          phase: __MODULE__,
          message: msg,
          locations: [field.source_location]
        }

        {:error, error}

      val ->
        raise """
        Invalid return from config function!

        A config function must return `{:ok, config}` or `{:error, msg}`. You returned:

        #{inspect(val)}
        """
    end
  end

  defp find_keys!(config) do
    case config[:topic] do
      nil ->
        raise """
        Subscription config must include a non null topic!

        #{inspect(config)}
        """

      [] ->
        raise """
        Subscription config must not provide an empty list of topics!

        #{inspect(config)}
        """

      val ->
        List.wrap(val)
        |> Enum.map(&to_string/1)
    end
  end

  defp ensure_pubsub!(context) do
    case Absinthe.Subscription.extract_pubsub(context) do
      {:ok, pubsub} ->
        pubsub

      _ ->
        raise """
        Pubsub not configured!

        Subscriptions require a configured pubsub module.
        """
    end
  end
end
