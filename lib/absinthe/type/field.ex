defmodule Absinthe.Type.Field do

  @moduledoc """
  Used to define a field.

  Usually these are defined using the `Absinthe.Type.Definitions.fields/1`
  convenience function.

  See the `t` type below for details and examples of how to define a field.
  """

  alias __MODULE__

  alias Absinthe.Type
  alias Absinthe.Type.Deprecation
  alias Absinthe.Schema

  @typedoc """
  The configuration for a field

  * `:name` - The name of the field, usually assigned automatically by
  the `Absinthe.Type.Definitions.fields/1` convenience function.
  * `:description` - Description of a field, useful for introspection.
  * `:deprecation` - Deprecation information for a field, usually
     set-up using the `Absinthe.Type.Definitions.deprecate/2` convenience
     function.
  * `:type` - The type the value of the field should resolve to
  * `:args` - The arguments of the field, usually created by using the
    `Absinthe.Type.Definitions.args/1` convenience function.
  * `resolve` - The resolution function. See below for more information.

  ## Resolution Functions

  ### Default

  If no resolution function is given, the default resolution function is used,
  which is roughly equivalent to this:

      {:ok, Map.get(parent_object, field_name)}

  This is commonly use when listing the available fields on a
  `Absinthe.Type.Object` that models a data record. For instance:

      @absinthe :type
      def person do
        %Absinthe.Type.Object{
          description: "A Person"
          fields: fields(
            first_name: [type: :string],
            last_name: [type: :string],
          )
        }
      end

  ### Custom Resolution

  When accepting arguments, however, you probably need do use them for
  something. Here's an example of definining a field that looks up a list of
  users for a given `location_id`:

      def query do
        %Absinthe.Type.Object{
          fields: fields(
            users: [
              type: :person,
              args: args(
                location_id: [type: non_null(:integer)]
              ),
              resolve: fn
                %{location_id: id}, _execution ->
                  {:ok, MyApp.users_for_location_id(id)}
              end
            ]
          )
        }
      end

  Custom resolution functions are passed two arguments:

  1. A map of the arguments for the field, filled in with values from the
     provided query document/variables.
  2. An `Absinthe.Execution` struct, containing the complete execution context
     (and useful for complex resolutions using the resolved parent object, etc)

  """
  @type t :: %{name: binary,
               description: binary | nil,
               type: Type.identifier_t,
               deprecation: Deprecation.t | nil,
               args: %{(binary | atom) => Absinthe.Type.Argument.t} | nil,
               resolve: ((any, %{binary => any} | nil, Absinthe.Type.ResolveInfo.t | nil) -> Absinthe.Type.output_t) | nil}

  defstruct name: nil, description: nil, type: nil, deprecation: nil, args: %{}, resolve: nil

  defimpl Absinthe.Validation.RequiredInput do

    # Whether the field is required.
    #
    # Note this is only useful for input object types.
    #
    # * If the field is deprecated, it is never required
    # * If the argumnet is not deprecated, it is required
    #   if its type is non-null
    @doc false
    @spec required?(Field.t) :: boolean
    def required?(%Field{type: type, deprecation: nil}) do
      type
      |> Absinthe.Validation.RequiredInput.required?
    end
    def required?(%Field{}) do
      false
    end

  end

  defimpl Absinthe.Traversal.Node do
    def children(node, traversal) do
      found = Schema.lookup_type(traversal.context, node.type)
      if found do
        [found | node.args |> Map.values]
      else
        type_names = traversal.context.types |> Map.keys |> Enum.join(", ")
        raise "Unknown Absinthe type for field `#{node.name}': (#{node.type |> Type.unwrap} not in available types, #{type_names})"
      end
    end
  end

end
