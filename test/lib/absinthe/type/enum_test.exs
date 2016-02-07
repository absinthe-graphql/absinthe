defmodule Absinthe.Type.EnumTest do
  use ExSpec, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

    query [
      fields: [
        channel: [
          description: "The active color channel"
        ]
      ]
    ]

    @doc "The selected color channel"
    enum :color_channel, [
      values: [
        red: [
          description: "Color Red",
          value: :r
        ],
        green: [
          description: "Color Green",
          value: :g
        ],
        blue: [
          description: "Color Blue",
          value: :b
        ],
        alpha: deprecate([
          description: "Alpha Channel",
          value: :a
        ], reason: "We no longer support opacity settings")
      ]
    ]

    @doc "The selected color channel"
    enum :color_channel2, [
      values: [
        red: [
          description: "Color Red"
        ],
        green: [
          description: "Color Green"
        ],
        blue: [
          description: "Color Blue"
        ],
        alpha: deprecate([
          description: "Alpha Channel"
        ], reason: "We no longer support opacity settings")
      ]
    ]

    @doc "The selected color channel"
    enum :color_channel3, [
      values: [:red, :green, :blue, :alpha]
    ]

  end

  describe "enums" do
    it "can be defined by a map with defined values" do
      type = TestSchema.__absinthe_type__(:color_channel)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "red", value: :r} = type.values[:red]
    end
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
