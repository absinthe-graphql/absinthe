defmodule Absinthe.Phase.Schema.Compile do
  alias Absinthe.Blueprint.Schema

  def run(blueprint, opts) do
    module_name = Module.concat(opts[:module], Compiled)

    %{schema_definitions: [schema]} = blueprint

    types = build_types(blueprint)

    type_list =
      Map.new(schema.types, fn type_def ->
        {type_def.identifier, type_def.name}
      end)

    metadata = build_metadata(schema)

    implementors = build_implementors(schema)

    body = [
      types,
      quote do
        def __absinthe_type__(_type) do
          nil
        end

        def __absinthe_types__ do
          unquote(Macro.escape(type_list))
        end

        def __absinthe_directives__() do
          %{}
        end

        def __absinthe_interface_implementors__() do
          unquote(Macro.escape(implementors))
        end
      end,
      metadata
    ]

    Module.create(module_name, body, Macro.Env.location(__ENV__))

    {:ok, blueprint}
  end

  def build_metadata(schema) do
    for type <- schema.types do
      quote do
        def __absinthe_reference__(unquote(type.identifier)) do
          unquote(Macro.escape(type.__reference__))
        end
      end
    end
  end

  def build_types(%{schema_definitions: [schema]}) do
    for %module{} = type_def <- schema.types do
      type = module.build(type_def, schema)

      type = %{
        type
        | definition: type_def.module,
          __reference__: type_def.__reference__,
          __private__: type_def.__private__
      }

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

  defp build_implementors(schema) do
    schema.types
    |> Enum.filter(&match?(%Schema.InterfaceTypeDefinition{}, &1))
    |> Map.new(fn iface ->
      implementors =
        Enum.sort(
          for %Schema.ObjectTypeDefinition{} = obj <- schema.types,
              iface.identifier in obj.interfaces,
              do: obj.identifier
        )

      {iface.identifier, implementors}
    end)
  end
end
