defmodule Absinthe.Language.ListValue do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  defstruct values: [],
            loc: nil

  @type t :: %__MODULE__{
          values: [Language.value_t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Input.List{
        items:
          node.values
          |> Enum.map(fn value ->
            %Blueprint.Input.RawValue{content: Blueprint.Draft.convert(value, doc)}
          end),
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.Document.SourceLocation.at(loc.start_line)
  end
end
