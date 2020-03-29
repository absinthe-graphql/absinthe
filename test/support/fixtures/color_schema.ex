defmodule Absinthe.Fixtures.ColorSchema do
  use Absinthe.Schema
  use Absinthe.Fixture

  @names %{
    r: "RED",
    g: "GREEN",
    b: "BLUE",
    p: "PUCE"
  }

  @values %{
    r: 100,
    g: 200,
    b: 300,
    p: -100
  }

  query do
    field :info,
      type: :channel_info,
      args: [
        channel: [type: non_null(:channel), default_value: :r]
      ],
      resolve: fn %{channel: channel}, _ ->
        {:ok, %{name: @names[channel], value: @values[channel]}}
      end

    field :infos,
      type: list_of(:channel_info),
      args: [
        channels: [type: list_of(:channel), default_value: [:r, :g]]
      ],
      resolve: fn %{channels: channels}, _ ->
        {:ok,
         Enum.map(channels, fn channel ->
           %{name: @names[channel], value: @values[channel]}
         end)}
      end

    field :more_infos,
      type: list_of(:channel_info),
      args: [
        channels: [type: list_of(:channel), default_value: :r]
      ],
      resolve: fn %{channels: channels}, _ ->
        {:ok,
         Enum.map(channels, fn channel ->
           %{name: @names[channel], value: @values[channel]}
         end)}
      end
  end

  @desc "A color channel"
  enum :channel do
    @desc "The color red"
    value :red, as: :r

    @desc "The color green"
    value :green, as: :g

    value :blue, description: "The color blue", as: :b
    value :puce, description: "The color puce", as: :p, deprecate: "it's ugly"
  end

  object :channel_info do
    description """
    Info about a channel
    """

    field :name, :string
    field :value, :integer
  end

  input_object :channel_input do
    field :channel, :channel, default_value: :r
  end
end
