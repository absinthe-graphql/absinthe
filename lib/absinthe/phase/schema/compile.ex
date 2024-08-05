defmodule Absinthe.Phase.Schema.Compile do
  @moduledoc false

  alias Absinthe.Blueprint.Schema

  def run(blueprint, opts) do
    module_name = Module.concat(opts[:schema], Compiled)

    %{schema_definitions: [schema]} = blueprint

    prototype_schema = Keyword.fetch!(opts, :prototype_schema)

    type_ast = build_types(schema.type_artifacts, prototype_schema)

    directive_ast = build_directives(schema.directive_artifacts)

    type_list =
      Map.new(schema.type_definitions, fn type_def ->
        {type_def.identifier, type_def.name}
      end)

    type_list =
      case prototype_schema do
        Absinthe.Schema.Prototype ->
          type_list

        prototype_schema ->
          Map.merge(type_list, prototype_schema.__absinthe_types__())
      end

    referenced_types =
      for type_def <- schema.type_definitions,
          type_def.__private__[:__absinthe_referenced__],
          into: %{},
          do: {type_def.identifier, type_def.name}

    referenced_types =
      case prototype_schema do
        Absinthe.Schema.Prototype ->
          referenced_types

        prototype_schema ->
          Map.merge(referenced_types, prototype_schema.__absinthe_types__(:referenced))
      end

    directive_list =
      Map.new(schema.directive_artifacts, fn type_def ->
        {type_def.identifier, type_def.name}
      end)

    metadata = build_metadata(schema)

    implementors = build_implementors(schema)

    body =
      quote do
        @moduledoc false

        unquote_splicing(type_ast)
        unquote_splicing(directive_ast)

        def __absinthe_types__() do
          __absinthe_types__(:referenced)
        end

        def __absinthe_types__(:referenced) do
          unquote(Macro.escape(referenced_types))
        end

        def __absinthe_types__(:all) do
          unquote(Macro.escape(type_list))
        end

        def __absinthe_directives__() do
          unquote(Macro.escape(directive_list))
        end

        def __absinthe_interface_implementors__() do
          unquote(Macro.escape(implementors))
        end

        def __absinthe_prototype_schema__() do
          unquote(Macro.escape(prototype_schema))
        end

        def __absinthe_schema_declaration__() do
          unquote(Macro.escape(schema.schema_declaration))
        end

        unquote_splicing(metadata)
      end

    Module.create(module_name, body, Macro.Env.location(__ENV__))

    {:ok, blueprint}
  end

  def build_metadata(schema) do
    for type <- schema.type_definitions do
      quote do
        def __absinthe_reference__(unquote(type.identifier)) do
          unquote(Macro.escape(type.__reference__))
        end
      end
    end
  end

  def build_types(types, prototype_schema) do
    for type <- types do
      if !type.definition,
        do:
          raise("""
          No definition set!
          #{inspect(type)}
          """)

      ast = Macro.escape(type, unquote: true)

      quote do
        def __absinthe_type__(unquote(type.identifier)) do
          unquote(ast)
        end

        def __absinthe_type__(unquote(type.name)) do
          __absinthe_type__(unquote(type.identifier))
        end
      end
    end
    |> Enum.concat([
      if prototype_schema == Absinthe.Schema.Prototype do
        quote do
          def __absinthe_type__(_type), do: nil
        end
      else
        quote do
          def __absinthe_type__(type), do: unquote(prototype_schema).__absinthe_type__(type)
        end
      end
    ])
  end

  def build_directives(directives) do
    for type <- directives do
      ast = Macro.escape(type)

      quote do
        def __absinthe_directive__(unquote(type.identifier)) do
          unquote(ast)
        end

        def __absinthe_directive__(unquote(type.name)) do
          __absinthe_directive__(unquote(type.identifier))
        end
      end
    end
    |> Enum.concat([
      quote do
        def __absinthe_directive__(_type) do
          nil
        end
      end
    ])
  end

  defp build_implementors(schema) do
    schema.type_definitions
    |> Enum.filter(&match?(%Schema.InterfaceTypeDefinition{}, &1))
    |> Map.new(fn iface ->
      implementors =
        Schema.InterfaceTypeDefinition.find_implementors(iface, schema.type_definitions)

      {iface.identifier, Enum.sort(implementors)}
    end)
  end
end
