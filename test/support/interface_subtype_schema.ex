defmodule Absinthe.InterfaceSubtypeSchema do
  use Absinthe.Schema

  # Example data
  @box %{
    item: %{name: "Computer", cost: 1000}
  }

  query do

    field :box,
      type: :box,
      args: [],
      resolve: fn _, _ ->
        {:ok, @box}
      end
  end

  object :box do
    field :item, :valued_item
    interface :has_item
    is_type_of fn _ -> true end
  end

  interface :has_item do
    field :item, :item
  end

  object :valued_item do
    field :name, :string
    field :cost, :integer

    interface :item
    is_type_of fn _ -> true end
  end

  interface :item do
    field :name, :string
  end
end
