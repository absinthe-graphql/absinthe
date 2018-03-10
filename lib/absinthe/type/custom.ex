defmodule Absinthe.Type.Custom do
  use Absinthe.Schema.Notation

  @moduledoc """
  This module contains the following additional data types:
  - datetime (UTC)
  - naive_datetime
  - date
  - time
  - decimal (only if [Decimal](https://hex.pm/packages/decimal) is available)

  Further description of these types can be found in the source code.

  To use: `import_types Absinthe.Type.Custom`.
  """

  scalar :datetime, name: "DateTime" do
    description """
    The `DateTime` scalar type represents a date and time in the UTC
    timezone. The DateTime appears in a JSON response as an ISO8601 formatted
    string, including UTC timezone ("Z"). The parsed date and time string will
    be converted to UTC and any UTC offset other than 0 will be rejected.
    """

    serialize &DateTime.to_iso8601/1
    parse &parse_datetime/1
  end

  scalar :naive_datetime, name: "NaiveDateTime" do
    description """
    The `Naive DateTime` scalar type represents a naive date and time without
    timezone. The DateTime appears in a JSON response as an ISO8601 formatted
    string.
    """

    serialize &NaiveDateTime.to_iso8601/1
    parse &parse_naive_datetime/1
  end

  scalar :date do
    description """
    The `Date` scalar type represents a date. The Date appears in a JSON
    response as an ISO8601 formatted string.
    """

    serialize &Date.to_iso8601/1
    parse &parse_date/1
  end

  scalar :time do
    description """
    The `Time` scalar type represents a time. The Time appears in a JSON
    response as an ISO8601 formatted string.
    """

    serialize &Time.to_iso8601/1
    parse &parse_time/1
  end

  if Code.ensure_loaded?(Decimal) do
    scalar :decimal do
      description """
      The `Decimal` scalar type represents signed double-precision fractional
      values parsed by the `Decimal` library.  The Decimal appears in a JSON
      response as a string to preserve precision.
      """

      serialize &Absinthe.Type.Custom.Decimal.serialize/1
      parse &Absinthe.Type.Custom.Decimal.parse/1
    end
  end

  @spec parse_datetime(Absinthe.Blueprint.Input.String.t()) :: {:ok, DateTime.t()} | :error
  @spec parse_datetime(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp parse_datetime(%Absinthe.Blueprint.Input.String{value: value}) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, 0} -> {:ok, datetime}
      {:ok, _datetime, _offset} -> :error
      _error -> :error
    end
  end

  defp parse_datetime(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp parse_datetime(_) do
    :error
  end

  @spec parse_naive_datetime(Absinthe.Blueprint.Input.String.t()) ::
          {:ok, NaiveDateTime.t()} | :error
  @spec parse_naive_datetime(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp parse_naive_datetime(%Absinthe.Blueprint.Input.String{value: value}) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, naive_datetime} -> {:ok, naive_datetime}
      _error -> :error
    end
  end

  defp parse_naive_datetime(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp parse_naive_datetime(_) do
    :error
  end

  @spec parse_date(Absinthe.Blueprint.Input.String.t()) :: {:ok, Date.t()} | :error
  @spec parse_date(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp parse_date(%Absinthe.Blueprint.Input.String{value: value}) do
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      _error -> :error
    end
  end

  defp parse_date(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp parse_date(_) do
    :error
  end

  @spec parse_time(Absinthe.Blueprint.Input.String.t()) :: {:ok, Time.t()} | :error
  @spec parse_time(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp parse_time(%Absinthe.Blueprint.Input.String{value: value}) do
    case Time.from_iso8601(value) do
      {:ok, time} -> {:ok, time}
      _error -> :error
    end
  end

  defp parse_time(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp parse_time(_) do
    :error
  end
end
