defmodule Absinthe.Type.EnumTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      field :channel, :color_channel, description: "The active color channel" do
        resolve fn _, _ ->
          {:ok, :red}
        end
      end
    end

    enum :color_channel do
      description "The selected color channel"
      value :red, as: :r, description: "Color Red"
      value :green, as: :g, description: "Color Green"
      value :blue, as: :b, description: "Color Blue"
      value :alpha, as: :a, deprecate: "We no longer support opacity settings", description: "Alpha Channel"
    end

    enum :color_channel2 do
      description "The selected color channel"

      value :red, description: "Color Red"
      value :green, description: "Color Green"
      value :blue, description: "Color Blue"
      value :alpha, as: :a, deprecate: "We no longer support opacity settings", description: "Alpha Channel"
    end

    enum :color_channel3,
      values: [:red, :green, :blue, :alpha],
      description: "The selected color channel"

  end

  describe "enums" do
    it "can be defined by a map with defined values" do
      type = TestSchema.__absinthe_type__(:color_channel)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "RED", value: :r, description: "Color Red"} = type.values[:red]
    end
    it "can be defined by a map without defined values" do
      type = TestSchema.__absinthe_type__(:color_channel2)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "RED", value: :red} = type.values[:red]
    end
    it "can be defined by a shorthand list of atoms" do
      type = TestSchema.__absinthe_type__(:color_channel3)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "RED", value: :red, description: nil} = type.values[:red]
    end
  end

end
