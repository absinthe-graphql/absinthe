defmodule Absinthe.Schema.Prototype do
  use Absinthe.Schema

  @pipeline_modifier __MODULE__

  directive :deprecated do
    arg :reason, :string
    on [:field_definition, :input_field_definition, :argument_definition]
    expand &__MODULE__.expand_deprecate/2
  end

  def pipeline(pipeline) do
    pipeline
    |> Absinthe.Pipeline.without(Absinthe.Phase.Schema.Validation.QueryTypeMustBeObject)
  end

  @doc """
  Add a deprecation (with an optional reason) to a node.
  """
  @spec expand_deprecate(
          arguments :: %{optional(:reason) => String.t()},
          node :: Absinthe.Blueprint.node_t()
        ) :: Absinthe.Blueprint.node_t()
  def expand_deprecate(arguments, node) do
    %{node | deprecation: %Absinthe.Type.Deprecation{reason: arguments[:reason]}}
  end
end
