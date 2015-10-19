defmodule ExGraphQL.Validation.Rules.ArgumentsOfCorrectType do

  @spec check(ExGraphQL.Validation.Context.t, ExGraphQL.Language.Node.t) :: [binary]
  def check(context, %{__struct__: mod}) do
    [mod]
  end

end
