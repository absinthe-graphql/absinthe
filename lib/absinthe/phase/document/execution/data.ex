defmodule Absinthe.Phase.Document.Execution.Data do

  @moduledoc """
  Produces data fit for external encoding from annotated value tree
  """

  alias Absinthe.{Blueprint, Phase}
  use Absinthe.Phase

  def run(blueprint) do
    result = blueprint |> process
    {:ok, result}
  end

  defp process(%Blueprint{} = blueprint) do
    blueprint
    |> Blueprint.current_operation
    |> do_process(blueprint.errors)
  end
  defp do_process(nil, top_errors) do
    format_result(nil, top_errors)
  end
  defp do_process(%Blueprint.Document.Operation{resolution: tree} = operation, top_errors) do
    document_errors = Enum.reduce(operation.fields, [], fn
      field, acc ->
        {_, acc} = Blueprint.prewalk(field, acc, &document_errors/2)
        acc
    end)
    {data, resolution_errors} = field_data(tree.fields, [])
    format_result(data, top_errors ++ document_errors ++ resolution_errors)
  end

  defp format_result(nil, errors) do
    %{errors: Enum.map(errors, &format_error/1)}
  end
  defp format_result(data, []) do
    %{data: data}
  end
  defp format_result(data, errors) do
    %{data: data, errors: Enum.map(errors, &format_error/1)}
  end

  defp document_errors(%{errors: errs} = node, acc) do
    {node, acc ++ errs}
  end
  defp document_errors(node, acc) do
    {node, acc}
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
  defp list_data([%{errors: errs} = field | fields], errors, acc) when length(errs) > 0 do
    list_data(fields, errs ++ errors, acc)
  end

  defp field_data(fields, errors, acc \\ [])
  defp field_data([], errors, acc), do: {:maps.from_list(acc), errors}
  defp field_data([%{errors: []} = field | fields], errors, acc) do
    {value, errors} = data(field, errors)
    field_data(fields, errors, [{field_name(field), value} | acc])
  end
  defp field_data([%{errors: errs} = field | fields], errors, acc) when length(errs) > 0 do
    field_data(fields, errs ++ errors, acc)
  end

  defp field_name(%{emitter: %{alias: nil, name: name}}), do: name
  defp field_name(%{emitter: %{alias: name}}), do: name
  defp field_name(%{emitter: %{name: name}}), do: name

  defp format_error(%Phase.Error{locations: []} = error) do
    %{message: error.message}
  end
  defp format_error(%Phase.Error{} = error) do
    %{message: error.message, locations: error.locations}
  end

end
