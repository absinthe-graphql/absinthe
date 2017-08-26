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

    with {:ok, field_key} <- get_field_key(blueprint, context) do
      Absinthe.Subscription.subscribe(pubsub, field_key, doc_id, blueprint)
      {:replace, blueprint, [{Absinthe.Phase.Subscription.Result, topic: doc_id}]}
    else
      error ->
        error
    end
  end

  defp get_field_key(blueprint, context) do
    %{schema_node: schema_node, argument_data: argument_data} = get_field(blueprint)
    name = schema_node.identifier

    key = case schema_node.topic do
      fun when is_function(fun, 2) ->
        apply(fun, [argument_data, context])
      fun when is_function(fun, 1) ->
        IO.write(:stderr, "Warning: 1-arity topic functions are deprecated, upgrade to 2 arity before 1.4.0 release")
        apply(fun, [argument_data])
      nil ->
        Atom.to_string(name)
    end

    case key do
      {:ok, key} ->
        {:ok, {name, key}}
      {:error, msg} ->
        {:error, msg}
      val ->
        raise """
        Invalid return from topic function!

        Topic function must returne `{:ok, topic}` or `{:error, msg}`. You returned:

        #{inspect val}
        """
    end
  end

  defp get_field(blueprint) do
    [field] =
      blueprint
      |> Absinthe.Blueprint.current_operation
      |> Map.fetch!(:selections)
    field
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
