defmodule Elixir.Absinthe.Integration.Execution.InputTypes.Enum.DefaultValueTest do
  use Absinthe.Case, async: true

  @query """
  query {
    default: info {
      name
      value
    }
    defaults: infos {
      name
      value
    }
  }
  """
  test "default values" do
    assert {:ok,
            %{
              data: %{
                "default" => %{"name" => "RED", "value" => 100},
                "defaults" => [
                  %{"name" => "RED", "value" => 100},
                  %{"name" => "GREEN", "value" => 200}
                ]
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ColorSchema, [])
  end

  test "Introspection renders default value properly" do
    {:ok, %{data: data}} =
      """
      {
        __schema {
          queryType {
            fields {
              name
              args {
                name
                defaultValue
              }
            }
          }
        }
      }
      """
      |> run(Absinthe.Fixtures.ColorSchema)

    fields = get_in(data, ["__schema", "queryType", "fields"])

    assert %{
             "args" => [%{"defaultValue" => "[RED]", "name" => "channels"}],
             "name" => "moreInfos"
           } in fields
  end
end
