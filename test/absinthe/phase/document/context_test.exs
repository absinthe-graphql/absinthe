defmodule Absinthe.Phase.Document.ContextTest do
  use Absinthe.Case, async: true

  alias Absinthe.Pipeline

  @context %{user: "Foo"}
  @root %{version: "0.0.1"}

  @compilation_pipeline Absinthe.Pipeline.for_document(nil, jump_phases: false)
                        |> Absinthe.Pipeline.before(Absinthe.Phase.Document.Variables)

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      field :user, :string do
        resolve(fn _root_value,
                   _args,
                   %{
                     context: %{
                       user: user
                     }
                   } ->
          {:ok, user}
        end)
      end

      field :version, :string do
        resolve(fn root_value, _args, _res ->
          {:ok, root_value.version}
        end)
      end
    end
  end

  describe "when context contains some value" do
    test "it is available during execution" do
      result =
        """
          query GetUser {
            user
          }
        """
        |> compile()
        |> execute()

      assert result == %{data: %{"user" => "Foo"}}
    end
  end

  describe "when root-value is set" do
    test "it is available during execution" do
      result =
        """
          query GetVersion {
            version
          }
        """
        |> compile()
        |> execute()

      assert result == %{data: %{"version" => @root.version}}
    end
  end

  defp compile(query) do
    {:ok, blueprint, _} = Pipeline.run(query, @compilation_pipeline)
    blueprint
  end

  defp execute(blueprint) do
    pipeline =
      Absinthe.Pipeline.for_document(
        TestSchema,
        context: @context,
        root_value: @root
      )

    start_phase =
      case List.last(@compilation_pipeline) do
        {mod, _} -> mod
        mod -> mod
      end

    execution_pipeline = Absinthe.Pipeline.from(pipeline, start_phase)

    {:ok, doc, _} = Pipeline.run(blueprint, execution_pipeline)
    doc.result
  end
end
