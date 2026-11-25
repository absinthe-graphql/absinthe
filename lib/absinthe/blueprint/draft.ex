defprotocol Absinthe.Blueprint.Draft do
  @moduledoc false

  def convert(node, root)
end

defimpl Absinthe.Blueprint.Draft, for: List do
  def convert(nodes, root) do
    Enum.flat_map(nodes, fn node ->
      case Absinthe.Blueprint.Draft.convert(node, root) do
        nil -> []
        converted -> [converted]
      end
    end)
  end
end

defimpl Absinthe.Blueprint.Draft, for: Atom do
  def convert(atom, _) do
    atom
  end
end
