defmodule Absinthe.Schema.Notation.Writer do

  defp type_functions(definition) do
    ast = build(:type, definition)
    quote bind_quoted: [identifier: definition.identifier, name: definition.attrs[:name], ast: ast] do
      def __absinthe_type__(identifier), do: ast
      def __absinthe_type__(name), do: __absinthe_type__(identifier)
    end
  end

  defp directive_functions(definition) do
    ast = build(:directive, definition)
    quote bind_quoted: [identifier: definition.identifier, name: definition.attrs[:name], ast: ast] do
      def __absinthe_directive__(identifier), do: ast
      def __absinthe_directive__(name), do: __absinthe_directive__(identifier)
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

  defmacro __before_compile__(env) do

    result = %{
      type_map: %{},
      directive_map: %{},
      errors: [],
      type_functions: [],
      directive_functions: [],
      exports: [],
      implementors: %{}
    }

    info = Module.get_attribute(env.module, :absinthe_definitions)
    |> Enum.reduce(result, fn
      %{category: :directive} = definition, acc ->
        %{acc |
          directive_map: Map.put(acc.directive_map, definition.identifier, definition.attrs[:name]),
          directive_functions: [directive_functions(definition) | acc.directive_functions],
          # TODO: Handle directive exports differently
          exports: (if Keyword.get(definition.opts, :export, true) do
            [definition.identifier | acc.exports]
          else
            acc.exports
          end),
         }
      %{category: :type} = definition, acc ->
        %{acc |
          type_map: Map.put(acc.type_map, definition.identifier, definition.attrs[:name]),
          type_functions: [type_functions(definition) | acc.type_functions],
          implementors: Enum.reduce(List.wrap(definition.attrs[:interfaces]), acc.implementors, fn
            iface, implementors ->
              update_in(implementors, [iface], fn
                nil ->
                  [definition.identifier]
                list ->
                  [definition.identifier | list]
              end)
          end),
          exports: (if Keyword.get(definition.opts, :export, true) do
            [definition.identifier | acc.exports]
          else
            acc.exports
          end)
         }
    end)

    [
      quote do
        def __absinthe_types__, do: unquote(info.type_map)
      end,
      info.type_functions,
      quote do
        def __absinthe_type_(_), do: nil
      end,
      quote do
        def __absinthe_directives__, do: unquote(info.directive_map)
      end,
      info.directive_functions,
      quote do
        def __absinthe_directive_(_), do: nil
      end,
      quote do
        def __absinthe_errors__, do: unquote(info.errors)
        def __absinthe_interface_implementors, do: unquote(info.implementors)
        def __absinthe_exports__, do: unquote(info.exports)
      end
    ]

  end

end
