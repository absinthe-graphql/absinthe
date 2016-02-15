defmodule PrefixSchema do

  use Absinthe.Schema

  query do
    field :foo do
      arg :bar
    end
    field :__mything,
      name: "__mything",
      type: :thing,
      args: [
        __myarg: [type: :integer]
      ],
      resolve: fn
        _, _ ->
          {:ok, %{name: "Test"}}
      end
  end

  object :__mything, name: "__MyThing" do
    field :name, :string
  end

  directive :__mydirective do

    @doc "Skipped when true."
    arg :__if, non_null(:boolean)

    on Language.FragmentSpread
    on Language.Field
    on Language.InlineFragment

    instruction fn
      %{if: true} ->
        :skip
      _ ->
        :include
    end

  end

end
