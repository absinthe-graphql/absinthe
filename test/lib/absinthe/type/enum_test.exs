defmodule Absinthe.Type.EnumTest do
  use ExSpec, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      @desc "The active color channel"
      field :channel, :color_channel
    end

    @desc "The selected color channel"
    enum :color_channel do

      @desc "Color Red"
      value :red, as: :r

      @desc "Color Green"
      value :green, as: :g

      @desc "Color Blue"
      value :blue, as: :b

      @desc "Alpha Channel"
      value :alpha, as: :a, deprecate: "We no longer support opacity settings"

    end

    @desc "The selected color channel"
    enum :color_channel2 do

      @desc "Color Red"
      value :red

      @desc "Color Green"
      value :green

      @desc "Color Blue"
      value :blue

      @desc "Alpha Channel"
      value :alpha, as: :a, deprecate: "We no longer support opacity settings"

    end

    @desc "The selected color channel"
    enum :color_channel3,
      values: [:red, :green, :blue, :alpha]

  end

  describe "enums" do
    it "can be defined by a map with defined values" do
      type = TestSchema.__absinthe_type__(:color_channel)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "red", value: :r, description: "Color Red"} = type.values[:red]
    end
    it "can be defined by a map without defined values" do
      type = TestSchema.__absinthe_type__(:color_channel2)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "red", value: :red} = type.values[:red]
    end
    it "can be defined by a shorthand list of atoms" do
      type = TestSchema.__absinthe_type__(:color_channel3)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "red", value: :red, description: nil} = type.values[:red]
    end
  end

end
