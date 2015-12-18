defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Language.Field do

  alias ExGraphQL.Execution
  alias ExGraphQL.Execution.Resolution
  alias ExGraphQL.Type
  alias ExGraphQL.Flag

  @spec resolve(ExGraphQL.Language.Field.t,
                ExGraphQL.Execution.t) :: {:ok, map} | {:error, any}
  def resolve(%{name: name} = ast_node, %{errors: errors, strategy: :serial, resolution: %{parent_type: parent_type, target: target}} = execution) do
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
            {:error, missing, exe} ->
              exe
              |> Execution.put_error(:field, name, describe_missing(missing), at: ast_node)
              |> Flag.as(:skip)
          end
      end
    else
      execution
      |> Execution.put_error(:field, ast_node.name, "Not present in schema", at: ast_node)
      |> Flag.as(:skip)
    end
  end

  # Generate a detailed error message for a list of missing arguments
  @spec describe_missing([binary]) :: binary
  defp describe_missing(missing) do
    {msg, listing} = do_describe_missing(missing)
    msg <> " (" <> listing <> ") not provided"
  end

  # Determine the error message parts
  @spec do_describe_missing([binary]) :: {binary, binary}
  defp do_describe_missing(missing) do
    quote_it = &"`#{&1}'"
    case missing do
      [item] -> {"1 required argument", quote_it.(item)}
      _ -> {"#{length(missing)}", missing |> Enum.map(quote_it) |> Enum.join(", ")}
    end
  end

  defp process_raw_result({:ok, value}, ast_node, field, execution) do
    value
    |> result(ast_node, field, execution)
  end
  defp process_raw_result({:error, errors}, ast_node, _field, execution) do
    errors
    |> List.wrap
    |> Enum.reduce(execution, fn
      value, exe -> Execution.put_error(exe, :field, ast_node.name, value, at: ast_node)
    end)
    |> Flag.as(:skip)
  end
  defp process_raw_result(_other, ast_node, _field, execution) do
    execution
    |> Execution.put_error(:field, ast_node.name, "Did not resolve to match {:ok, _} or {:error, _}", at: ast_node)
    |> Flag.as(:skip)
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
