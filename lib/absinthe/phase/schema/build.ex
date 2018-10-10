defmodule Absinthe.Phase.Schema.Build do
  @moduledoc false

  def run(blueprint, _opts) do
    %{schema_definitions: [schema]} = blueprint

    types = build_types(blueprint)
    directives = build_directives(blueprint)

    schema = %{schema | type_artifacts: types, directive_artifacts: directives}

    blueprint = %{blueprint | schema_definitions: [schema]}

    {:ok, blueprint}
  end

  def build_types(%{schema_definitions: [schema]}) do
    for %module{} = type_def <- schema.type_definitions do
      type = module.build(type_def, schema)

      %{
        type
        | __reference__: type_def.__reference__,
          __private__: type_def.__private__
      }
    end
  end

  def build_directives(%{schema_definitions: [schema]}) do
    for %module{} = type_def <- schema.directive_definitions do
      type = module.build(type_def, schema)

      %{
        type
        | definition: type_def.module,
          __reference__: type_def.__reference__,
          __private__: type_def.__private__
      }
    end
  end
end
