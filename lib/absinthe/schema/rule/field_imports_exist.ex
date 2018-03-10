defmodule Absinthe.Schema.Rule.FieldImportsExist do
  @moduledoc false
  # This has to be run prior to the module compilation, and is called
  # from Notation.Writer instead of Rule
  def check({definitions, errors}) do
    definition_map = build_definition_map(definitions)

    errors =
      Enum.reduce(definitions, errors, fn definition, errors ->
        definition.attrs
        |> Keyword.get(:field_imports)
        |> case do
          [_ | _] = imports ->
            check_imports(definition, imports, definition_map, errors)

          _ ->
            errors
        end
      end)

    {definitions, errors}
  end

  defp check_imports(definition, imports, definition_map, errors) do
    Enum.reduce(imports, errors, fn {ref, _}, errors ->
      case Map.fetch(definition_map, ref) do
        {:ok, _} ->
          errors

        _ ->
          [error(definition, ref) | errors]
      end
    end)
  end

  defp build_definition_map(definitions) do
    definitions
    |> Enum.filter(&Map.get(&1, :identifier))
    |> Map.new(&{&1.identifier, &1})
  end

  def explanation(%{data: %{artifact: msg}}) do
    """
      #{msg}
    """
    |> String.trim()
  end

  defp error(definition, ref) do
    msg =
      """
      Field Import Error

      Object #{inspect(definition.identifier)} imports fields from #{inspect(ref)} but
      #{inspect(ref)} does not exist in the schema!
      """
      |> String.trim()

    %{
      data: %{artifact: msg, value: ref},
      location: %{file: definition.file, line: definition.line},
      rule: __MODULE__
    }
  end
end
