defmodule Absinthe.Type.BuiltIns.Scalars.Utils do

  # Parse, supporting pulling values out of AST nodes
  defmacro parse_with(node_types, coercion) do
    quote do
      fn
       %{value: value} = node ->
       if Enum.is_member?(unquote(node_types), node) do
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
