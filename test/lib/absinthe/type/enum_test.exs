defmodule Absinthe.Type.EnumTest do
  use ExSpec, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      @doc "The active color channel"
      field :channel, :color_channel
    end

    @doc "The selected color channel"
    enum :color_channel do

      @doc "Color Red"
      value :red, as: :r

      @doc "Color Green"
      value :green, as: :g

      @doc "Color Blue"
      value :blue, as: :b

      @doc "Alpha Channel"
      @deprecate "We no longer support opacity settings"
      value :alpha, as: :a

    end

    @doc "The selected color channel"
    enum :color_channel2 do

      @doc "Color Red"
      value :red

      @doc "Color Green"
      value :green

      @doc "Color Blue"
      value :blue

      @doc "Alpha Channel"
      value :alpha, as: :a, deprecate: "We no longer support opacity settings"

    end

    @doc "The selected color channel"
    enum :color_channel3,
      values: [:red, :green, :blue, :alpha]

  end

  describe "enums" do
    it "can be defined by a map with defined values" do
      type = TestSchema.__absinthe_type__(:color_channel)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "red", value: :r} = type.values[:red]
    end
    @tag :value
    it "can be defined by a map without defined values" do
      type = TestSchema.__absinthe_type__(:color_channel2)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "red", value: :red} = type.values[:red]
    end
    it "can be defined by a shorthand list of atoms" do
      type = TestSchema.__absinthe_type__(:color_channel3)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "red", value: :red} = type.values[:red]
    end
  end

end
