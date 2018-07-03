defmodule Absinthe.Language.Argument do
  @moduledoc false

  alias Absinthe.Blueprint

  defstruct name: nil,
            value: nil,
            loc: %{}

  @type t :: %__MODULE__{
          name: String.t(),
          value: %{value: any},
          loc: Absinthe.Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Input.Argument{
        name: node.name,
        input_value: %Blueprint.Input.RawValue{
          content: Absinthe.Blueprint.Draft.convert(node.value, doc)
        },
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)
  end

  defimpl Absinthe.Traversal.Node do
    def children(node, _schema) do
      [node.value]
    end
  end
end
