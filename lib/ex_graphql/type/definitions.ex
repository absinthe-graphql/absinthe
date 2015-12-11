defmodule ExGraphQL.Type.Definitions do

  defmacro fields(definitions) do
    quote do
      fn ->
        named(ExGraphQL.Type.FieldDefinition, unquote(definitions))
      end
    end
  end

  def args(definitions) do
    named(ExGraphQL.Type.Argument, definitions)
  end

  def named(mod, definitions) do
    definitions
    |> Enum.into(%{}, fn ({identifier, definition}) ->
      {
        identifier,
        struct(mod, [{:name, identifier |> to_string} | definition])
      }
    end)
  end

end
