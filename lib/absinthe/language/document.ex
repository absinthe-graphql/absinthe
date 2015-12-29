defmodule Absinthe.Language.Document do
  # The parsed AST representation of a query document"

  @moduledoc false

  @typedoc false
  @type t :: %{definitions: [Absinthe.Traversal.Node.t], loc: Absinthe.Language.loc_t}
  defstruct definitions: [], loc: %{start_line: nil}

  @doc false
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

  defimpl Absinthe.Traversal.Node do
    def children(%{definitions: definitions}, _schema), do: definitions
  end

end
