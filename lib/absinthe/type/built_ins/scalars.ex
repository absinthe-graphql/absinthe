defmodule Absinthe.Type.BuiltIns.Scalars do
  use Absinthe.Schema.Notation

  @moduledoc false

  scalar :integer, name: "Int" do
    description """
    The `Int` scalar type represents non-fractional signed whole numeric values.
    Int can represent values between `-(2^53 - 1)` and `2^53 - 1` since it is
    represented in JSON as double-precision floating point numbers specified
    by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
    """
    serialize &(&1)
    parse parse_with([Absinthe.Blueprint.Input.Integer], &parse_int/1)
  end

  scalar :float do
    description """
    The `Float` scalar type represents signed double-precision fractional
    values as specified by
    [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
    """
    serialize &(&1)
    parse parse_with([Absinthe.Blueprint.Input.Integer,
                      Absinthe.Blueprint.Input.Float], &parse_float/1)
  end


  scalar :string do
    description """
    The `String` scalar type represents textual data, represented as UTF-8
    character sequences. The String type is most often used by GraphQL to
    represent free-form human-readable text.
    """
    serialize &to_string/1
    parse parse_with([Absinthe.Blueprint.Input.String], &parse_string/1)
  end

  scalar :id, name: "ID" do
    description """
    The `ID` scalar type represents a unique identifier, often used to
    refetch an object or as key for a cache. The ID type appears in a JSON
    response as a String; however, it is not intended to be human-readable.
    When expected as an input type, any string (such as `"4"`) or integer
    (such as `4`) input value will be accepted as an ID.
    """

    serialize &to_string/1
    parse parse_with([Absinthe.Blueprint.Input.Integer,
                       Absinthe.Blueprint.Input.String], &parse_id/1)
  end

  scalar :boolean do
    description """
    The `Boolean` scalar type represents `true` or `false`.
    """

    serialize &(&1)
    parse parse_with([Absinthe.Blueprint.Input.Boolean], &parse_boolean/1)
  end

  scalar :utc_datetime, name: "DateTime" do
    description """
    The `UTC DateTime` scalar type represents a date and time in the UTC
    timezone. The DateTime appears in a JSON response as an ISO8601 formatted
    string, including UTC timezone ("Z").
    """

    serialize &DateTime.to_iso8601/1
    parse parse_with([Absinthe.Blueprint.Input.DateTime], &parse_utc_datetime/1)
  end

  scalar :datetime, name: "NaiveDateTime" do
    description """
    The `DateTime` scalar type represents a naive date and time without
    timezone. The DateTime appears in a JSON response as an ISO8601 formatted
    string.
    """

    serialize &NaiveDateTime.to_iso8601/1
    parse parse_with([Absinthe.Blueprint.Input.NaiveDateTime], &parse_datetime/1)
  end

  scalar :date do
    description """
    The `Date` scalar type represents a date. The Date appears in a JSON
    response as an ISO8601 formatted string.
    """

    serialize &Date.to_iso8601/1
    parse parse_with([Absinthe.Blueprint.Input.Date], &parse_date/1)
  end

  # Integers are only safe when between -(2^53 - 1) and 2^53 - 1 due to being
  # encoded in JavaScript and represented in JSON as double-precision floating
  # point numbers, as specified by IEEE 754.
  @max_int 9007199254740991
  @min_int -9007199254740991

  @spec parse_int(any) :: {:ok, integer} | :error
  defp parse_int(value) when is_integer(value) and value >= @min_int and value <= @max_int do
    {:ok, value}
  end
  defp parse_int(_) do
    :error
  end

  @spec parse_float(any) :: {:ok, float} | :error
  defp parse_float(value) when is_float(value) do
    {:ok, value}
  end
  defp parse_float(value) when is_integer(value) do
    {:ok, value * 1.0}
  end
  defp parse_float(_) do
    :error
  end

  @spec parse_string(any) :: {:ok, binary} | :error
  defp parse_string(value) when is_binary(value) do
    {:ok, value}
  end
  defp parse_string(_) do
    :error
  end

  @spec parse_id(any) :: {:ok, binary} | :error
  defp parse_id(value) when is_binary(value) do
    {:ok, value}
  end
  defp parse_id(value) when is_integer(value) do
    {:ok, Integer.to_string(value)}
  end
  defp parse_id(_) do
    :error
  end

  @spec parse_boolean(any) :: {:ok, boolean} | :error
  defp parse_boolean(value) when is_boolean(value) do
    {:ok, value}
  end
  defp parse_boolean(_) do
    :error
  end

  @spec parse_utc_datetime(any) :: {:ok, DateTime.t} | :error
  defp parse_utc_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, utc_datetime, _offset} -> {:ok, utc_datetime}
      _error -> :error
    end
  end
  defp parse_utc_datetime(_) do
    :error
  end

  @spec parse_datetime(any) :: {:ok, NaiveDateTime.t} | :error
  defp parse_datetime(value) when is_binary(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, datetime} -> {:ok, datetime}
      _error -> :error
    end
  end
  defp parse_datetime(_) do
    :error
  end

  @spec parse_date(any) :: {:ok, Date.t} | :error
  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      _error -> :error
    end
  end
  defp parse_date(_) do
    :error
  end


  # Parse, supporting pulling values out of blueprint Input nodes
  defp parse_with(node_types, coercion) do
    fn
      %{__struct__: str, value: value} ->
        if Enum.member?(node_types, str) do
          coercion.(value)
        else
          :error
        end
      other ->
        coercion.(other)
    end
  end

end
