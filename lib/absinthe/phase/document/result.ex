defmodule Absinthe.Phase.Document.Result do

  @moduledoc false

  # Produces data fit for external encoding from annotated value tree

  alias Absinthe.{Blueprint, Phase}
  use Absinthe.Phase

  @spec run(Blueprint.t | Phase.Error.t, Keyword.t) :: {:ok, map}
  def run(input, _options \\ []) do
    result = input |> process
    {:ok, result}
  end

  defp process(%Phase.Error{} = error) do
    format_result({:parse_failed, error})
  end
  defp process(%Blueprint{} = blueprint) do
    result = case blueprint.resolution do
      %{validation: [], result: nil} ->
        :execution_failed
      %{validation: [], result: result} ->
        {:ok, field_data(result.fields, [])}
      %{validation: errors} ->
        {:validation_failed, errors}
    end
    format_result(result)
  end

  defp format_result(:execution_failed) do
    %{data: nil}
  end
  defp format_result({:ok, {data, []}}) do
    %{data: data}
  end
  defp format_result({:ok, {data, errors}}) do
    errors = errors |> Enum.uniq |> Enum.map(&format_error/1)
    %{data: data, errors: errors}
  end
  defp format_result({:validation_failed, errors}) do
    errors = errors |> Enum.uniq |> Enum.map(&format_error/1)
    %{errors: errors}
  end
  defp format_result({:parse_failed, error}) do
    %{errors: [format_error(error)]}
  end

  # Leaf
  defp data(%{value: value}, errors), do: {value, errors}

  # Object
  defp data(%{fields: fields}, errors), do: field_data(fields, errors)

  # List
  defp data(%{values: values}, errors), do: list_data(values, errors)

  defp list_data(fields, errors, acc \\ [])
  defp list_data([], errors, acc), do: {:lists.reverse(acc), errors}
  defp list_data([%{errors: []} = field | fields], errors, acc) do
    {value, errors} = data(field, errors)
    list_data(fields, errors, [value | acc])
  end
  defp list_data([%{errors: errs} | fields], errors, acc) when length(errs) > 0 do
    list_data(fields, errs ++ errors, acc)
  end

  defp deep_merge(list) when is_list(list) and length(list) <= 1 do
    :maps.from_list(list)
  end
  defp deep_merge(list) when is_list(list) do
    list
    |> Enum.map(&Map.new([&1]))
    |> Enum.reduce(&do_deep_merge/2)
  end

  def do_deep_merge(right, left) do
    Map.merge(left, right, &do_deep_resolve/3)
  end

  defp do_deep_resolve(_key, [%{} = left], [%{} = right]) do
    [do_deep_merge(right, left)]
  end
  defp do_deep_resolve(_key, %{} = left, %{} = right) do
    do_deep_merge(right, left)
  end
  defp do_deep_resolve(_key, _left, right) do
   right
  end

  defp field_data(fields, errors, acc \\ [])
  defp field_data([], errors, acc), do: {deep_merge(acc), errors}
  defp field_data([%{errors: []} = field | fields], errors, acc) do
    {value, errors} = data(field, errors)
    field_data(fields, errors, [{field_name(field), value} | acc])
  end
  defp field_data([%{errors: errs} | fields], errors, acc) when length(errs) > 0 do
    field_data(fields, errs ++ errors, acc)
  end

  defp field_name(%{emitter: %{alias: nil, name: name}}), do: name
  defp field_name(%{emitter: %{alias: name}}), do: name
  defp field_name(%{emitter: %{name: name}}), do: name

  defp format_error(%Phase.Error{locations: []} = error) do
    error_object = %{message: error.message}
    Map.merge(error.extra, error_object)
  end
  defp format_error(%Phase.Error{} = error) do
    error_object = %{
      message: error.message,
      locations: Enum.map(error.locations, &format_location/1)
    }
    Map.merge(Map.new(error.extra), error_object)
  end

  defp format_location(%{line: line, column: col}) do
    %{line: line || 0, column: col || 0}
  end

end
