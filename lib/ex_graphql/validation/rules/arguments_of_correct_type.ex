defmodule ExGraphQL.Validation.Rules.ArgumentsOfCorrectType do

  alias ExGraphQL.Validation.Context
  alias ExGraphQL.Utility

  @spec check(ExGraphQL.Validation.Context.t, ExGraphQL.Language.Node.t) :: [binary]
  def check(context, %{__struct__: mod}) do
    arg_def = context |> Context.argument
    if arg_def && Utility.valid_literal_value?(arg_def.type, node.value) do
      [error(node, arg_def)]
    else
      []
    end
  end

  defp error(node, arg_def) do
    "Argument \"#{node.name.value}\" expected type \"#{arg_def.type}\" but got: #{inspect(node.value)}."
  end

end
