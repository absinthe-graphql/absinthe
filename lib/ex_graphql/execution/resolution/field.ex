defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Language.Field do

  alias ExGraphQL.Execution
  alias ExGraphQL.Execution.Resolution
  alias ExGraphQL.Type
  alias ExGraphQL.Flag

  @spec resolve(ExGraphQL.Language.Field.t,
                ExGraphQL.Execution.t) :: {:ok, map} | {:error, any}
  def resolve(%{name: name} = ast_node, %{strategy: :serial, resolution: %{parent_type: parent_type, target: target}} = execution) do
    field = Type.field(parent_type, ast_node.name)
    if field do
      case field do
        %{resolve: nil} ->
          target |> Map.get(name |> String.to_atom) |> result(ast_node, field, execution)
        %{resolve: resolver} ->
          case Execution.Arguments.build(ast_node, field.args, execution) do
            {:ok, args, exe} ->
              resolver.(args, exe)
              |> process_raw_result(ast_node, field, exe)
            {:error, {missing, invalid}, exe} ->
              exe
              |> skip_as(:missing, missing, name, ast_node)
              |> skip_as(:invalid, invalid, name, ast_node)
              |> Flag.as(:skip)
          end
      end
    else
      execution
      |> Execution.put_error(:field, ast_node.name, "Not present in schema", at: ast_node)
      |> Flag.as(:skip)
    end
  end

  defp skip_as(execution, _reason, [], _name, _ast_node) do
    execution
  end
  defp skip_as(execution, reason, collected, name, ast_node) do
    execution
    |> Execution.put_error(:field, name, describe(collected, reason), at: ast_node)
  end

  @reasons %{missing: %{prefix: "required argument", suffix: "not provided"},
             invalid: %{prefix: "badly formed argument", suffix: "provided"}}

  # Generate a detailed error message for a list of missing arguments
  @spec describe([binary], atom) :: binary
  defp describe(collected, reason) do
    {msg, listing} = do_describe(collected, reason)
    msg <> " (" <> listing <> ") " <> @reasons[reason].suffix
  end

  # Determine the error message parts
  @spec do_describe([binary], :atom) :: {binary, binary}
  defp do_describe(collected, reason) do
    quote_it = &"`#{&1}'"
    prefix = @reasons[reason].prefix
    case collected do
      [item] -> {"1 #{prefix}", quote_it.(item)}
      _ -> {"#{length(collected)} #{prefix}s", collected |> Enum.map(quote_it) |> Enum.join(", ")}
    end
  end

  defp process_raw_result({:ok, value}, ast_node, field, execution) do
    exe_with_deprecation = add_field_deprecation(execution, field, ast_node)
    value
    |> result(ast_node, field, exe_with_deprecation)
  end
  defp process_raw_result({:error, errors}, ast_node, field, execution) do
    errors
    |> List.wrap
    |> Enum.reduce(execution, fn
      value, exe -> Execution.put_error(exe, :field, ast_node.name, value, at: ast_node)
    end)
    |> add_field_deprecation(field, ast_node)
    |> Flag.as(:skip)
  end
  defp process_raw_result(_other, ast_node, field, execution) do
    execution
    |> add_field_deprecation(field, ast_node)
    |> Execution.put_error(:field, ast_node.name, "Did not resolve to match {:ok, _} or {:error, _}", at: ast_node)
    |> Flag.as(:skip)
  end

  defp add_field_deprecation(execution, %{deprecation: nil}, _ast_node) do
    execution
  end
  defp add_field_deprecation(execution, %{name: name, deprecation: %{reason: reason}}, ast_node) do
    details = if reason, do: "; #{reason}", else: ""
    execution
    |> Execution.put_error(:field, name, "Deprecated" <> details, at: ast_node)
  end

  defp result(nil, _ast_node, _field, execution) do
    {:ok, nil, execution}
  end
  defp result(value, ast_node, field, execution) do
    resolved_type = Type.resolve_type(field.type, value)
    next_resolution = %Resolution{type: resolved_type, ast_node: ast_node, target: value}
    Resolution.resolve(resolved_type, %{execution | resolution: next_resolution})
  end

end
