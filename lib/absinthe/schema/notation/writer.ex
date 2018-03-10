defmodule Absinthe.Schema.Notation.Writer do
  @moduledoc false

  defstruct [
    :env,
    type_map: %{},
    directive_map: %{},
    errors: [],
    type_functions: [],
    directive_functions: [],
    exports: [],
    implementors: %{}
  ]

  defmacro __before_compile__(env) do
    info = build_info(env)

    errors = Macro.escape(info.errors)
    exports = Macro.escape(info.exports)
    type_map = Macro.escape(info.type_map)
    implementors = Macro.escape(info.implementors)
    directive_map = Macro.escape(info.directive_map)

    [
      quote do
        def __absinthe_types__, do: unquote(type_map)
      end,
      info.type_functions,
      quote do
        def __absinthe_type__(_), do: nil
      end,
      quote do
        def __absinthe_directives__, do: unquote(directive_map)
      end,
      info.directive_functions,
      quote do
        def __absinthe_directive__(_), do: nil
      end,
      quote do
        def __absinthe_errors__, do: unquote(errors)
        def __absinthe_interface_implementors__, do: unquote(implementors)
        def __absinthe_exports__, do: unquote(exports)
      end
    ]
  end

  defp init_implementors(nil) do
    %{}
  end

  defp init_implementors(modules) do
    modules
    |> Enum.map(& &1.__absinthe_interface_implementors__)
    |> Enum.reduce(%{}, fn implementors, acc ->
      Map.merge(implementors, acc, fn _k, v1, v2 ->
        v1 ++ v2
      end)
    end)
  end

  def build_info(env) do
    implementors =
      env.module
      |> Module.get_attribute(:absinthe_imports)
      |> init_implementors

    descriptions =
      env.module
      |> Module.get_attribute(:absinthe_descriptions)
      |> Map.new()

    definitions =
      env.module
      |> Module.get_attribute(:absinthe_definitions)
      |> Enum.map(&update_description(&1, descriptions))

    {definitions, errors} =
      {definitions, []}
      |> Absinthe.Schema.Rule.FieldImportsExist.check()
      |> Absinthe.Schema.Rule.NoCircularFieldImports.check()

    info = %__MODULE__{
      env: env,
      errors: errors,
      implementors: implementors
    }

    Enum.reduce(definitions, info, &do_build_info/2)
  end

  defp type_functions(definition) do
    ast = build(:type, definition)
    identifier = definition.identifier
    name = definition.attrs[:name]

    result = [
      quote(do: def(__absinthe_type__(unquote(name)), do: __absinthe_type__(unquote(identifier))))
    ]

    if definition.builder == Absinthe.Type.Object do
      [
        quote do
          def __absinthe_type__(unquote(identifier)) do
            unquote(ast)
          end
        end,
        result
      ]
    else
      [
        quote do
          def __absinthe_type__(unquote(identifier)), do: unquote(ast)
        end,
        result
      ]
    end
  end

  defp directive_functions(definition) do
    ast = build(:directive, definition)
    identifier = definition.identifier
    name = definition.attrs[:name]

    quote do
      def __absinthe_directive__(unquote(identifier)), do: unquote(ast)
      def __absinthe_directive__(unquote(name)), do: __absinthe_directive__(unquote(identifier))
    end
  end

  # Type import reference
  defp build(:type, %{source: source, builder: nil} = definition) do
    quote bind_quoted: [source: source, identifier: definition.identifier] do
      source.__absinthe_type__(identifier)
    end
  end

  # Directive import reference
  defp build(:directive, %{source: source, builder: nil} = definition) do
    quote bind_quoted: [source: source, identifier: definition.identifier] do
      source.__absinthe_directive__(identifier)
    end
  end

  # Type/Directive definition
  defp build(_, %{source: nil, builder: builder} = definition) do
    builder.build(definition)
  end

  defp directive_name_error(definition) do
    %{
      rule: Absinthe.Schema.Rule.TypeNamesAreUnique,
      location: %{file: definition.file, line: definition.line},
      data: %{artifact: "Absinthe directive identifier", value: definition.identifier}
    }
  end

  defp type_name_error(artifact, value, definition) do
    %{
      rule: Absinthe.Schema.Rule.TypeNamesAreUnique,
      location: %{file: definition.file, line: definition.line},
      data: %{artifact: artifact, value: value}
    }
  end

  defp directive_errors(definition, state) do
    case Map.has_key?(state.directive_map, definition.identifier) do
      true ->
        [directive_name_error(definition)]

      false ->
        []
    end
  end

  defp type_errors(definition, state) do
    [
      if Map.has_key?(state.type_map, definition.identifier) do
        type_name_error("Absinthe type identifier", definition.identifier, definition)
      end,
      if Enum.member?(Map.values(state.type_map), definition.attrs[:name]) do
        type_name_error("Type name", definition.attrs[:name], definition)
      end
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp update_description(definition, descriptions) do
    case Map.get(descriptions, definition.identifier) do
      nil -> definition
      desc -> Map.update!(definition, :attrs, &Keyword.put(&1, :description, desc))
    end
  end

  defp do_build_info(%{category: :directive} = definition, info) do
    errors = directive_errors(definition, info)

    info
    |> update_directive_map(definition)
    |> update_directive_functions(definition, errors)
    |> update_exports(definition)
    |> update_errors(errors)
  end

  defp do_build_info(%{category: :type} = definition, info) do
    errors = type_errors(definition, info)

    info
    |> update_type_map(definition)
    |> update_type_functions(definition, errors)
    |> update_implementors(definition)
    |> update_exports(definition)
    |> update_errors(errors)
  end

  defp update_directive_map(info, definition) do
    Map.update!(
      info,
      :directive_map,
      &Map.put(&1, definition.identifier, definition.attrs[:name])
    )
  end

  defp update_directive_functions(info, definition, []) do
    Map.update!(info, :directive_functions, &[directive_functions(definition) | &1])
  end

  defp update_type_map(info, definition) do
    Map.update!(info, :type_map, &Map.put(&1, definition.identifier, definition.attrs[:name]))
  end

  defp update_type_functions(info, definition, []) do
    Map.update!(info, :type_functions, &[type_functions(definition) | &1])
  end

  defp update_type_functions(info, _definition, _errors), do: info

  defp update_implementors(info, definition) do
    implementors =
      definition.attrs[:interfaces]
      |> List.wrap()
      |> Enum.reduce(info.implementors, fn iface, implementors ->
        Map.update(implementors, iface, [definition.identifier], &[definition.identifier | &1])
      end)

    %{info | implementors: implementors}
  end

  defp update_exports(info, definition) do
    exports =
      if Keyword.get(definition.opts, :export, definition.source != Absinthe.Type.BuiltIns) do
        [definition.identifier | info.exports]
      else
        info.exports
      end

    %{info | exports: exports}
  end

  defp update_errors(info, errors) do
    %{info | errors: errors ++ info.errors}
  end
end
