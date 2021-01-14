defmodule HydrateDynamicValuesTest do
  use ExUnit.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    enum :color do
      value :red
      value :blue
      value :green
    end

    query do
      field :all, list_of(:color) do
        resolve fn _, _, _ -> {:ok, [1, 2, 3]} end
      end
    end

    def hydrate(
          %Absinthe.Blueprint.Schema.EnumValueDefinition{identifier: identifier},
          [%Absinthe.Blueprint.Schema.EnumTypeDefinition{identifier: :color}]
        ) do
      {:as, color_map(identifier)}
    end

    def hydrate(_, _) do
      []
    end

    defp color_map(:red), do: 1
    defp color_map(:blue), do: 2
    defp color_map(:green), do: 3
  end

  test "can hydrate enum values dynamically" do
    assert {:ok, %{data: %{"all" => ["RED", "BLUE", "GREEN"]}}} == Absinthe.run("{ all }", Schema)
  end
end
