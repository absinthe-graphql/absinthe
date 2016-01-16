defmodule Absinthe.Type.Directive do

  @moduledoc """
  Used by the GraphQL runtime as a way of modifying execution
  behavior.

  Type system creators will usually not create these directly.
  """

  alias Absinthe.Type
  use Absinthe.Introspection.Kind

  @typedoc """
  A defined directive.

  * `:name` - The name of the directivee. Should be a lowercase `binary`. Set automatically when using `@absinthe :directive` from `Absinthe.Type.Definitions`.
  * `:description` - A nice description for introspection.
  * `:args` - A map of `Absinthe.Type.Argument` structs. See `Absinthe.Type.Definitions.args/1`.
  * `:on` - A list of places the directives can be used (can be `:operation`, `:fragment`, `:field`).

  The `:reference` key is for internal use.
  """
  @type t :: %{name: binary, description: binary, args: map, on: [atom], reference: Type.Reference.t}
  defstruct name: nil, description: nil, args: nil, on: [], reference: nil

 use Absinthe.Type.Definitions
 alias Absinthe.Type

 @absinthe :directive
 def include do
   %Type.Directive{
     description: "Directs the executor to include this field or fragment only when the `if` argument is true.",
     args: args(
       if: [type: non_null(:boolean), description: "Included when true."]
     ),
     on: [:fragment, :field]
   }
 end

 @absinthe :directive
 def skip do
   %Type.Directive{
     description: "Directs the executor to skip this field or fragment when the `if` argument is true.",
     args: args(
       if: [type: non_null(:boolean), description: "Skipped when true."]
     ),
     on: [:fragment, :field]
   }
 end

 # Whether the directive is active in `place`
 @spec on?(t, atom) :: boolean
 def on?(%{on: places}, place) do
   Enum.member?(places, place)
 end

end
