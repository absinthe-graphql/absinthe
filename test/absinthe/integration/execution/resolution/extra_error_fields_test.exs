defmodule Elixir.Absinthe.Integration.Execution.Resolution.ExtraErrorFieldsTest do
  use Absinthe.Case, async: true
  alias Absinthe.Pipeline
  alias Absinthe.Phase

  @query """
  mutation { failingThing(type: WITH_CODE) { name } }
  """

  test "extra fields places in errors list" do
    assert {:ok,
            %{
              data: %{"failingThing" => nil},
              errors: [
                %{
                  code: 42,
                  message: "Custom Error",
                  path: ["failingThing"],
                  locations: [%{column: 12, line: 1}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end

  test "extra fields placed in extensions" do
    pipeline =
      Pipeline.for_document(Absinthe.Fixtures.Things.MacroSchema)
      |> Pipeline.replace(
        Phase.Document.Result,
        {Phase.Document.Result, spec_compliant_errors: true}
      )

    assert {:ok,
            %{
              result: %{
                data: %{"failingThing" => nil},
                errors: [
                  %{
                    message: "Custom Error",
                    path: ["failingThing"],
                    locations: [%{column: 12, line: 1}],
                    extensions: %{code: 42}
                  }
                ]
              }
            }, _} = Pipeline.run(@query, pipeline)
  end

  @query """
  mutation { failingThing(type: MULTIPLE) { name } }
  """
  test "when no extra fields, extensions field is omitted" do
    pipeline =
      Pipeline.for_document(Absinthe.Fixtures.Things.MacroSchema)
      |> Pipeline.replace(
        Phase.Document.Result,
        {Phase.Document.Result, spec_compliant_errors: true}
      )

    assert {:ok,
            %{
              result: %{
                data: %{"failingThing" => nil},
                errors: [
                  %{locations: [%{column: 12, line: 1}], message: "one", path: ["failingThing"]},
                  %{locations: [%{column: 12, line: 1}], message: "two", path: ["failingThing"]}
                ]
              }
            }, _} = Pipeline.run(@query, pipeline)
  end
end
