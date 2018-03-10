defmodule Absinthe.Type.BuiltIns.Scalars.Utils do
  @moduledoc false

  # Parse, supporting pulling values out of AST nodes
  defmacro parse_with(node_types, coercion) do
    quote do
      fn
        %{value: value} = node ->
          if Enum.member?(unquote(node_types), node) do
            unquote(coercion).(value)
          else
            nil
          end

        other ->
          unquote(coercion).(other)
      end
    end
  end
end
