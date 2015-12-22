defmodule Absinthe.Language.Document do

  @type t :: %{definitions: [Absinthe.Language.Node.t], loc: Absinthe.Language.loc_t}
  defstruct definitions: [], loc: %{start: nil}

  @spec fragments_by_name(Absinthe.Language.Document.t) :: %{binary => Absinthe.Language.FragmentDefinition.t}
  def fragments_by_name(%{definitions: definitions}) do
    definitions
    |> Enum.reduce(%{}, fn (statement, memo) ->
      case statement do
        %Absinthe.Language.FragmentDefinition{} ->
          memo |> Map.put(statement.name, statement)
        _ ->
          memo
      end
    end)
  end

  defimpl Absinthe.Language.Node do
    def children(%{definitions: definitions}), do: definitions
  end

end
