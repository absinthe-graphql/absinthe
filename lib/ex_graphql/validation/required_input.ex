defprotocol ExGraphQL.Validation.RequiredInput do

  @fallback_to_any true

  @doc "Whether input from/of a given type is required"
  @spec required?(ExGraphQLType.t) :: boolean
  def required?(t)

end

defimpl ExGraphQL.Validation.RequiredInput, for: Any do

  @doc "Input of a type is required if it is non-null"
  @spec required?(ExGraphQL.Type.t) :: boolean
  def required?(type), do: ExGraphQL.Type.non_null?(type)

end
