defmodule Absinthe.IntegrationCase.Definition do

  @enforce_keys [:name, :schema, :graphql, :settings]

  defstruct [
    :name,
    :schema,
    :graphql,
    settings: [],
  ]

  @type expect_exception :: {:raise, module}
  @type expectation :: Absinthe.run_result | expect_exception
  @type setting :: {Absinthe.run_opts, expectation}

  @type t :: %__MODULE__{
    name: String.t,
    schema: Absinthe.Schema.t,
    graphql: String.t,
    settings: [setting],
  }

  def create(name, graphql, default_schema, settings) do
    %__MODULE__{
      name: name,
      graphql: graphql,
      schema: normalize_schema(default_schema, graphql),
      settings: normalize_settings(settings),
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

  defp normalize_settings(settings) do
    List.wrap(settings)
    |> Enum.map(&do_normalize_settings/1)
  end
  defp do_normalize_settings({_options, {_, _} = _result} = setting), do: setting
  defp do_normalize_settings(result), do: {[], result}

end
