defmodule Absinthe.Schema.Manager do
  use GenServer

  def start_link(schema) do
    GenServer.start_link(__MODULE__, schema, [])
  end

  def init(schema_module) do
    prototype_schema = schema_module.__absinthe_prototype_schema__

    pipeline =
      schema_module
      |> Absinthe.Pipeline.for_schema(prototype_schema: prototype_schema)
      |> Absinthe.Schema.apply_modifiers(schema_module)

    schema_module.__absinthe_blueprint__
    |> Absinthe.Pipeline.run(pipeline)
    |> case do
      {:ok, _, _} ->
        []

      {:error, errors, _} ->
        raise Absinthe.Schema.Error, phase_errors: List.wrap(errors)
    end

    {:ok, schema_module}
  end
end
