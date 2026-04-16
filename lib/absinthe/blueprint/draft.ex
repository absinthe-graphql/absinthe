defprotocol Absinthe.Blueprint.Draft do
  @moduledoc false

  def convert(node, root)
end

defimpl Absinthe.Blueprint.Draft, for: List do
  def convert(nodes, root) do
    nodes
    |> Enum.map(&Absinthe.Blueprint.Draft.convert(&1, root))
    # Comments are converted to `nil` values to be ignored
    |> Enum.reject(&is_nil/1)
  end
end

defimpl Absinthe.Blueprint.Draft, for: Atom do
  def convert(atom, _) do
    atom
  end
end
