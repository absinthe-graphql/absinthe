defmodule Absinthe.Phase.Schema.Compile do
  def run(blueprint, opts) do
    module_name = Module.concat(opts[:module], Compiled)

    types = build_types(blueprint)

    body = [
      types,
      quote do
        def __absinthe_type__(_type) do
          nil
        end
      end
    ]

    Module.create(module_name, body, Macro.Env.location(__ENV__))

    {:ok, blueprint}
  end

  def build_types(%{schema_definitions: [schema]}) do
    for %module{} = type_def <- schema.types do
      type =
        type_def
        |> module.build(schema)
        |> Macro.escape()

      quote do
        def __absinthe_type__(unquote(type_def.identifier)) do
          unquote(type)
        end

        def __absinthe_type__(unquote(type_def.name)) do
          unquote(type)
        end
      end
    end
  end
end
