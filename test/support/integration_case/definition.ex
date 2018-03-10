defmodule Absinthe.IntegrationCase.Definition do
  @enforce_keys [:name, :schema, :graphql, :scenarios]

  defstruct [
    :name,
    :schema,
    :graphql,
    scenarios: []
  ]

  @type expect_exception :: {:raise, module}
  @type expectation :: Absinthe.run_result() | expect_exception | :custom_assertion
  @type scenario :: {Absinthe.run_opts(), expectation}

  @type t :: %__MODULE__{
          name: String.t(),
          schema: Absinthe.Schema.t(),
          graphql: String.t(),
          scenarios: [scenario]
        }

  def create(name, graphql, default_schema, scenarios) do
    %__MODULE__{
      name: name,
      graphql: graphql,
      schema: normalize_schema(default_schema, graphql),
      scenarios: normalize_scenarios(scenarios)
    }
  end

  defp normalize_schema(default_schema, graphql) do
    case Regex.run(~r/^#\s*schema:\s*(\S+)/i, graphql) do
      nil ->
        default_schema

      [_, schema_name] ->
        Module.concat(Absinthe.Fixtures, String.to_atom(schema_name))
    end
  end

  defp normalize_scenarios(scenarios) do
    List.wrap(scenarios)
    |> Enum.map(&normalize_scenario/1)
  end

  defp normalize_scenario({_options, {_, _} = _result} = scenario), do: scenario
  defp normalize_scenario(result), do: {[], result}
end
