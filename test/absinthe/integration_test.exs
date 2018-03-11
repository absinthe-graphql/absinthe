defmodule Absinthe.IntegrationTest do
  @moduledoc """
  See the `Absinthe.IntegrationCase` documentation for information on
  how to write integration tests.
  """

  use Absinthe.IntegrationCase,
    root: "test/absinthe/integration",
    default_schema: Absinthe.Fixtures.ThingsSchema,
    async: true

  def assert_scenario(
        %{name: "execution/fragments/introspection"} = definition,
        {options, _expectation}
      ) do
    result = run(definition.graphql, definition.schema, options)

    assert {:ok,
            %{
              data: %{
                "__type" => %{
                  "name" => "ProfileInput",
                  "kind" => "INPUT_OBJECT",
                  "fields" => nil,
                  "inputFields" => input_fields
                }
              }
            }} = result

    correct = [%{"name" => "code"}, %{"name" => "name"}, %{"name" => "age"}]
    sort = & &1["name"]
    assert Enum.sort_by(input_fields, sort) == Enum.sort_by(correct, sort)
  end

  def assert_scenario(
        %{name: "execution/introspection/schema_types"} = definition,
        {options, _expectation}
      ) do
    result = run(definition.graphql, definition.schema, options)
    assert {:ok, %{data: %{"__schema" => %{"types" => types}}}} = result
    names = types |> Enum.map(& &1["name"]) |> Enum.sort()

    expected =
      ~w(Int String Boolean Contact Person Business ProfileInput SearchResult NamedEntity RootMutationType RootQueryType RootSubscriptionType __Schema __Directive __DirectiveLocation __EnumValue __Field __InputValue __Type)
      |> Enum.sort()

    assert expected == names
  end

  def assert_scenario(
        %{name: "execution/introspection/full"} = definition,
        {options, _expectation}
      ) do
    result = run(definition.graphql, definition.schema, options)
    {:ok, %{data: %{"__schema" => schema}}} = result
    assert !is_nil(schema)
  end
end
