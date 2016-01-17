defmodule Absinthe.Execution.Directives do

  alias Absinthe.Execution
  alias Absinthe.Schema
  alias Absinthe.Type

  def check(execution, %{directives: ast_directives} = ast_node) do
    Enum.reduce(ast_directives, {[], execution}, fn
      ast_directive, {results, acc_execution} ->
        case Schema.lookup_directive(execution.schema, ast_directive.name) do
          nil ->
            {
              results,
              acc_execution |> Execution.put_error(:directive, ast_directive.name, "Not defined", at: ast_directive)
            }
          definition ->
            case Execution.Arguments.build(ast_directive, definition.args, execution) do
              {:ok, args, checked_execution} ->
                case Type.Directive.check(definition, ast_node, args) do
                  true ->
                    {[definition.reference.identifier|results], checked_execution}
                  false ->
                    {results, checked_execution}
                end
              {:error, checked_execution} ->
                {results, checked_execution}
            end
        end
    end)
    |> reduce_results
  end
  def check(_, _) do
    :ok
  end

  @precedence [:include, :skip]
  defp reduce_results({results, execution}) do
    {
      results |> do_reduce_results,
      execution
    }
  end
  defp do_reduce_results(results) do
    results
    |> Enum.sort_by(fn
      result ->
        Enum.find_index(results, &(&1 == result)) || -1
    end)
    |> List.last || :ok
  end

end
