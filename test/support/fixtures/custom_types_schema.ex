defmodule Absinthe.Fixtures.CustomTypesSchema do
  use Absinthe.Schema
  use Absinthe.Fixture

  import_types Absinthe.Type.Custom

  @custom_types %{
    datetime: %DateTime{
      year: 2017,
      month: 1,
      day: 27,
      hour: 20,
      minute: 31,
      second: 55,
      time_zone: "Etc/UTC",
      zone_abbr: "UTC",
      utc_offset: 0,
      std_offset: 0
    },
    naive_datetime: ~N[2017-01-27 20:31:55],
    date: ~D[2017-01-27],
    time: ~T[20:31:55],
    decimal: Decimal.new("-3.49")
  }

  query do
    field :custom_types_query, :custom_types_object do
      resolve fn _, _ -> {:ok, @custom_types} end
    end
  end

  mutation do
    field :custom_types_mutation, :result do
      arg :args, :custom_types_input
      resolve fn _, _ -> {:ok, %{message: "ok"}} end
    end
  end

  object :custom_types_object do
    field :datetime, :datetime
    field :naive_datetime, :naive_datetime
    field :date, :date
    field :time, :time
    field :decimal, :decimal
  end

  object :result do
    field :message, :string
  end

  input_object :custom_types_input do
    field :datetime, :datetime
    field :naive_datetime, :naive_datetime
    field :date, :date
    field :time, :time
    field :decimal, :decimal
  end
end
