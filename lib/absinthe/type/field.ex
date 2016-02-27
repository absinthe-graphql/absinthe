defmodule Absinthe.Type.Field do
  alias Absinthe.Type

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

  use Type.Fetch

  @typedoc """
  A resolver function.

  See the `Absinthe.Type.Field.t` explanation of `:resolve` for more information.
  """
  @type resolver_t :: ((%{atom => any}, Absinthe.Execution.Field.t) -> {:ok, any} | {:error, binary})

  @typedoc """
  The configuration for a field.

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
  * `default_value` - The default value of a field. Note this is not used during resolution; only fields that are part of an `Absinthe.Type.InputObject` should set this value.

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
                %{location_id: id}, _ ->
                  {:ok, MyApp.users_for_location_id(id)}
              end
            ]
          )
        }
      end

  Custom resolution functions are passed two arguments:

  1. A map of the arguments for the field, filled in with values from the
     provided query document/variables.
  2. An `Absinthe.Execution.Field` struct, containing the execution environment
     for the field (and useful for complex resolutions using the resolved source
     object, etc)

  """
  @type t :: %{name: binary,
               description: binary | nil,
               type: Type.identifier_t,
               deprecation: Deprecation.t | nil,
               default_value: any,
               args: %{(binary | atom) => Absinthe.Type.Argument.t} | nil,
               resolve: resolver_t | nil,
               __reference__: Type.Reference.t}

  defstruct name: nil, description: nil, type: nil, deprecation: nil, args: %{}, resolve: nil, default_value: nil, __reference__: nil

  @doc """
  Build an AST of the field map for inclusion in other types

  ## Examples

  ```
  iex> build_map_ast([foo: [type: :string], bar: [type: :integer]])
  {:%{}, [],
   [foo: {:%, [],
     [{:__aliases__, [alias: false], [:Absinthe, :Type, :Field]},
      {:%{}, [], [name: "Foo", type: :string]}]},
    bar: {:%, [],
     [{:__aliases__, [alias: false], [:Absinthe, :Type, :Field]},
      {:%{}, [], [name: "Bar", type: :integer]}]}]}
  ```
  """
  @spec build(Keyword.t) :: tuple
  def build(fields) when is_list(fields) do
    quoted_empty_map = quote do: %{}
    ast = for {field_name, field_attrs} <- fields do
      name = field_name |> Atom.to_string
      field_data = [name: name] ++ Keyword.update(field_attrs, :args, quoted_empty_map, fn
        args ->
          Type.Argument.build(args || [])
      end)
      field_ast = quote do: %Absinthe.Type.Field{unquote_splicing(field_data |> Absinthe.Type.Deprecation.from_attribute)}
      {field_name, field_ast}
    end
    quote do: %{unquote_splicing(ast)}
  end

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
        type_names = traversal.context.types.by_identifier |> Map.keys |> Enum.join(", ")
        raise "Unknown Absinthe type for field `#{node.name}': (#{node.type |> Type.unwrap} not in available types, #{type_names})"
      end
    end
  end

end
