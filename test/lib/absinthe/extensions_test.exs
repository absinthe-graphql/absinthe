defmodule Absinthe.ExtensionsTest do
  use Absinthe.Case, async: false, ordered: false

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :foo, :string do
        middleware :resolve_foo
      end
    end

    def resolve_foo(res, _opts) do
      %{res |
        value: "hello world",
        state: :resolved,
        extensions: %{foo: 1},
      }
    end
  end

  defmodule MyPhase do
    # rolls up the extensions data into a top level result
    def run(blueprint, _) do
      extensions = get_ext(blueprint.execution.result.fields)
      result = Map.put(blueprint.result, :extensions, extensions)
      {:ok, %{blueprint | result: result}}
    end

    defp get_ext([field]) do
      field.extensions
    end
  end

  it "sets the extensions on the result properly" do
    doc = "{foo}"

    pipeline =
      Schema
      |> Absinthe.Pipeline.for_document()
      |> Absinthe.Pipeline.insert_after(Absinthe.Utils.getDefaultDocumentResult(), MyPhase)

    assert {:ok, bp, _} = Absinthe.Pipeline.run(doc, pipeline)

    assert bp.result == %{data: %{"foo" => "hello world"}, extensions: %{foo: 1}}
  end
end
