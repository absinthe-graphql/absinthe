defprotocol Absinthe.Blueprint.Draft do
  @moduledoc false

  def convert(node, root)
end

defimpl Absinthe.Blueprint.Draft, for: List do
  def convert(nodes, root) do
    Enum.map(nodes, &Absinthe.Blueprint.Draft.convert(&1, root))
  end
end

defimpl Absinthe.Blueprint.Draft, for: Atom do
  def convert(atom, _) do
    atom
  end
end
