defmodule ExGraphQL.AST.Document do
  defstruct definitions: [], loc: %{start: nil}

  @spec fragments_by_name(%ExGraphQL.AST.Document{}) :: %{binary => %ExGraphQL.AST.FragmentDefinition{}}
  def fragments_by_name(%{definitions: definitions}) do
    definitions
    |> Enum.reduce %{}, fn (statement, memo) ->
      case statement do
        %{__struct__: ExGraphQL.AST.FragmentDefinition} ->
          memo |> Map.put(statement.name, statement)
        _ ->
          memo
      end
    end

  end
end
