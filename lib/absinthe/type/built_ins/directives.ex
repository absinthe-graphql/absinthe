defmodule Absinthe.Type.BuiltIns.Directives do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint

  directive :include do
    description """
    Directs the executor to include this field or fragment only when the `if` argument is true.
    """

    arg :if, non_null(:boolean), description: "Included when true."

    on [:field, :fragment_spread, :inline_fragment]

    repeatable false

    expand fn
      %{if: true}, node ->
        Blueprint.put_flag(node, :include, __MODULE__)

      _, node ->
        Blueprint.put_flag(node, :skip, __MODULE__)
    end
  end

  directive :skip do
    description """
    Directs the executor to skip this field or fragment when the `if` argument is true.
    """

    repeatable false

    arg :if, non_null(:boolean), description: "Skipped when true."

    on [:field, :fragment_spread, :inline_fragment]

    expand fn
      %{if: true}, node ->
        Blueprint.put_flag(node, :skip, __MODULE__)

      _, node ->
        Blueprint.put_flag(node, :include, __MODULE__)
    end
  end

  directive :defer do
    description """
    Directs the executor to defer this fragment spread or inline fragment, 
    delivering it as part of a subsequent response. Used to improve latency 
    for data that is not immediately required.
    """

    repeatable false

    arg :if, :boolean, 
      default_value: true,
      description: "When true, fragment may be deferred. When false, fragment will not be deferred and data will be included in the initial response. Defaults to true."
    
    arg :label, :string,
      description: "A unique label for this deferred fragment, used to identify it in the incremental response."

    on [:fragment_spread, :inline_fragment]

    expand fn
      %{if: false}, node ->
        # Don't defer when if: false
        {:ok, node}

      args, node ->
        # Mark node for deferred execution
        defer_config = %{
          label: Map.get(args, :label),
          enabled: true
        }
        {:ok, Blueprint.put_flag(node, :defer, defer_config)}
    end
  end

  directive :stream do
    description """
    Directs the executor to stream list fields, delivering list items incrementally 
    in multiple responses. Used to improve latency for large lists.
    """

    repeatable false

    arg :if, :boolean,
      default_value: true,
      description: "When true, list field may be streamed. When false, list will not be streamed and all data will be included in the initial response. Defaults to true."
    
    arg :label, :string,
      description: "A unique label for this streamed field, used to identify it in the incremental response."
    
    arg :initial_count, :integer,
      default_value: 0,
      description: "The number of list items to return in the initial response. Defaults to 0."

    on [:field]

    expand fn
      %{if: false}, node ->
        # Don't stream when if: false
        {:ok, node}

      args, node ->
        # Mark node for streaming execution
        stream_config = %{
          label: Map.get(args, :label),
          initial_count: Map.get(args, :initial_count, 0),
          enabled: true
        }
        {:ok, Blueprint.put_flag(node, :stream, stream_config)}
    end
  end
end
