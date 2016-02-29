defprotocol Absinthe.Validation.RequiredInput do

  @moduledoc false

  @fallback_to_any true

  @doc "Whether input from/of a given type is required"
  @spec required?(AbsintheType.t) :: boolean
  def required?(t)

end

defimpl Absinthe.Validation.RequiredInput, for: Any do

  @doc "Input of a type is required if it is non-null"
  @spec required?(Absinthe.Type.t) :: boolean
  def required?(type), do: Absinthe.Type.non_null?(type)

end
