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

        def __absinthe_types__ do
          []
        end
      end
    ]

    Module.create(module_name, body, Macro.Env.location(__ENV__))

    {:ok, blueprint}
  end

  def build_types(%{schema_definitions: [schema]}) do
    for %module{} = type_def <- schema.types do
      type = module.build(type_def, schema)
      ast = Macro.escape(type)

      quote do
        def __absinthe_type__(unquote(type_def.identifier)) do
          unquote(ast)
        end

        def __absinthe_type__(unquote(type_def.name)) do
          unquote(ast)
        end
      end
    end
  end
end
