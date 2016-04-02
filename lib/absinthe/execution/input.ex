defmodule Absinthe.Execution.Input do
  @moduledoc false

  # Common functionality for Arguments and Variables

  alias Absinthe.Execution
  alias __MODULE__.Meta

  def process(input_type, meta, execution) do
    name = input_type
    |> Atom.to_string
    |> String.capitalize

    {execution, missing} = process_errors(execution, meta, input_type, :missing, fn type_name ->
      &"#{name} `#{&1}' (#{type_name}): Not provided"
    end)

    {execution, invalid} = process_errors(execution, meta, input_type, :invalid, fn type_name ->
      &"#{name} `#{&1}' (#{type_name}): Invalid value provided"
    end)

    {execution, _} = process_errors(execution, meta, input_type, :extra, &"#{name} `#{&1}': Not present in schema")

    {execution, _} = process_errors(execution, meta, input_type, :deprecated, nil)

    case Enum.any?(missing) || Enum.any?(invalid) do
      true ->
        {:error, missing, invalid, execution}
      false ->
        {:ok, execution}
    end
  end

  def process_errors(execution, meta, kind, key, default_msg) do
    meta
    |> Map.fetch!(key)
    |> Enum.reduce({execution, []}, fn
      %{name: name, ast: ast, type: type, msg: msg}, {exec, names} ->
        name = name |> dotted_name(execution.adapter)
        exec = exec |> Execution.put_error(kind, name, error_message(msg || default_msg, type), at: ast)

        {exec, [name | names]}
    end)
  end

  @compile {:inline, parse_scalar: 5}
  def parse_scalar(nil, _, _, _type_stack, meta) do
    {:ok, nil, meta}
  end
  def parse_scalar(value, ast, %{parse: parser} = type, type_stack, meta) do
    case parser.(value) do
      {:ok, coerced_value} ->
        {:ok, coerced_value, meta}

      :error ->
        {:error, Meta.put_invalid(meta, type_stack, type, ast)}
    end
  end

  defp error_message(msg, nil), do: msg
  defp error_message(msg, type) when is_function(msg) do
    msg.(type.name)
  end
  defp error_message(msg, _), do: msg

  @spec dotted_name([binary], atom) :: binary
  def dotted_name(names, adapter) do
    names
    |> do_dotted_names(adapter, [])
    |> IO.iodata_to_binary
  end

  defp do_dotted_names([name | []], adapter, acc) do
    [format_name(name, adapter) | acc]
  end
  defp do_dotted_names(["[]" | rest], adapter, acc) do
    do_dotted_names(rest, adapter, ["[]" | acc])
  end
  defp do_dotted_names([name | rest], adapter, acc) do
    do_dotted_names(rest, adapter, [ ".", format_name(name, adapter) | acc])
  end

  defp format_name(name, adapter) do
    name
    |> to_string
    |> adapter.to_external_name(:argument)
  end
end
