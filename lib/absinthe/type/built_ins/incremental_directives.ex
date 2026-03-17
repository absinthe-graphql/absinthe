defmodule Absinthe.Type.BuiltIns.IncrementalDirectives do
  @moduledoc """
  Draft-spec incremental delivery directives: @defer and @stream.

  These directives are part of the [Incremental Delivery RFC](https://github.com/graphql/graphql-spec/blob/main/rfcs/DeferStream.md)
  and are not yet part of the finalized GraphQL specification.

  ## Usage

  To enable @defer and @stream in your schema, import this module:

      defmodule MyApp.Schema do
        use Absinthe.Schema

        import_directives Absinthe.Type.BuiltIns.IncrementalDirectives

        query do
          # ...
        end
      end

  You will also need to enable incremental delivery in your pipeline:

      pipeline_modifier = fn pipeline, _options ->
        Absinthe.Pipeline.Incremental.enable(pipeline,
          enabled: true,
          enable_defer: true,
          enable_stream: true
        )
      end

      Absinthe.run(query, MyApp.Schema,
        variables: variables,
        pipeline_modifier: pipeline_modifier
      )

  ## Directives

  - `@defer` - Defers execution of a fragment spread or inline fragment
  - `@stream` - Streams list field items incrementally
  """

  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint

  directive :defer do
    description """
    Directs the executor to defer this fragment spread or inline fragment,
    delivering it as part of a subsequent response. Used to improve latency
    for data that is not immediately required.
    """

    repeatable false

    arg :if, :boolean,
      default_value: true,
      description:
        "When true, fragment may be deferred. When false, fragment will not be deferred and data will be included in the initial response. Defaults to true."

    arg :label, :string,
      description:
        "A unique label for this deferred fragment, used to identify it in the incremental response."

    on [:fragment_spread, :inline_fragment]

    expand fn
      %{if: false}, node ->
        # Don't defer when if: false
        node

      args, node ->
        # Mark node for deferred execution
        defer_config = %{
          label: Map.get(args, :label),
          enabled: true
        }

        Blueprint.put_flag(node, :defer, defer_config)
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
      description:
        "When true, list field may be streamed. When false, list will not be streamed and all data will be included in the initial response. Defaults to true."

    arg :label, :string,
      description:
        "A unique label for this streamed field, used to identify it in the incremental response."

    arg :initial_count, :integer,
      default_value: 0,
      description: "The number of list items to return in the initial response. Defaults to 0."

    on [:field]

    expand fn
      %{if: false}, node ->
        # Don't stream when if: false
        node

      args, node ->
        # Mark node for streaming execution
        stream_config = %{
          label: Map.get(args, :label),
          initial_count: Map.get(args, :initial_count, 0),
          enabled: true
        }

        Blueprint.put_flag(node, :stream, stream_config)
    end
  end
end
