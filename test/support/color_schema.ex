defmodule ColorSchema do
  use Absinthe.Schema

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

  query [
    fields: [
      info: [
        type: :channel_info,
        args: [
          channel: [type: non_null(:channel)],
        ],
        resolve: fn
          %{channel: channel}, _ ->
            {:ok, %{name: @names[channel], value: @values[channel]}}
        end
      ]
    ]
  ]

  @doc """
  A color channel
  """
  enum :channel, [
    values: [
      red: [description: "The color red", value: :r],
      green: [description: "The color green", value: :g],
      blue: [description: "The color blue", value: :b],
      puce: deprecate([description: "The color puce", value: :p], reason: "it's ugly")
    ]
  ]

  @doc """
  Info about a channel
  """
  object :channel_info, [
    fields: [
      name: [type: :string],
      value: [type: :integer]
    ]
  ]

end
