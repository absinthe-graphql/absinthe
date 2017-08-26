defmodule Absinthe.Phase.Subscription.SubscribeSelf do
  use Absinthe.Phase

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t) :: {:ok, Blueprint.t}
  def run(blueprint, _ \\ []) do
    with %{type: :subscription} <- Blueprint.current_operation(blueprint) do
      do_subscription(blueprint)
    else
      _ -> {:ok, blueprint}
    end
  end

  def do_subscription(blueprint) do
    context = blueprint.resolution.context
    pubsub = ensure_pubsub!(context)

    hash = :erlang.phash2(blueprint)
    doc_id = "__absinthe__:doc:#{hash}"

    for field_key <- field_keys(blueprint, context) do
      Absinthe.Subscription.subscribe(pubsub, field_key, doc_id, blueprint)
    end

    {:replace, blueprint, [{Absinthe.Phase.Subscription.Result, topic: doc_id}]}
  end

  defp field_keys(doc, context) do
    doc
    |> Absinthe.Blueprint.current_operation
    |> Map.fetch!(:selections)
    |> Enum.map(fn %{schema_node: schema_node, argument_data: argument_data} ->
      name = schema_node.__reference__.identifier

      key = case schema_node.topic do
        fun when is_function(fun, 2) ->
          apply(fun, [argument_data, context])
        fun when is_function(fun, 1) ->
          IO.write(:stderr, "Warning: 1-arity topic functions are deprecated, upgrade to 2 arity before 1.4.0 release")
          apply(fun, [argument_data])
        nil ->
          Atom.to_string(name)
      end

      {name, key}
    end)
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
