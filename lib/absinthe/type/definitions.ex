defmodule Absinthe.Type.Definitions do

  @moduledoc "Utility functions to define new types"

  alias Absinthe.Type

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :absinthe_types, accumulate: true)
      @on_definition unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  def __on_definition__(env, kind, name, _args, _guards, _body) do
    absinthe_attr = Module.get_attribute(env.module, :absinthe)
    Module.put_attribute(env.module, :absinthe, nil)
    if absinthe_attr do
      case {kind, absinthe_attr} do
        {:def, :type} ->
          Module.put_attribute(env.module, :absinthe_types, {name, name})
        {:def, [{:type, identifier}]} ->
          Module.put_attribute(env.module, :absinthe_types, {identifier, name})
        {:defp, _} -> raise  "Absinthe type definition #{name} must be a def, not defp"
        _ -> raise "Unknown absinthe definition for #{name}"
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc false
      def absinthe_types do
        @absinthe_types
        |> Enum.into(%{}, fn {identifier, fn_name} ->
          ready = apply(__MODULE__, fn_name, [])
          |> Absinthe.Type.Definitions.set_default_name(identifier)
          tagged = %{ready | reference: %Absinthe.Type.Reference{module: __MODULE__, identifier: identifier, name: ready.name}}
          {identifier, tagged}
        end)
      end
    end
  end

  # Add a name field to a type (using the absinthe type identifier)
  # unless it's already been defined.
  @doc false
  @spec set_default_name(Type.t, atom) :: Type.t
  def set_default_name(%{name: nil} = type, identifier) do
    %{type | name: identifier |> to_string |> Macro.camelize}
  end
  def set_default_name(%{name: _} = type, _identifier) do
    type
  end

  @doc """
  Deprecate a field or argument with an optional reason

  ## Examples

  Wrap around an argument or a field definition
  (of a `Absinthe.Type.InputObjectType`) to deprecate it:

  ```
  args(
    name: deprecate([type: :string, description: "The person's name"])
    # ...
  )
  ```

  You can also provide a reason:

  args(
    age: deprecate([type: :integer, description: "The person's age"],
                   reason: "None of your business!")
    # ...
  )

  Some usage information for deprecations:

  * They make non-null types nullable.
  * Currently use of a deprecated argument/field causes an error to be added to the `:errors` entry of a result.
  """
  @spec deprecate(Keyword.t) :: Keyword.t
  @spec deprecate(Keyword.t, Keyword.t) :: Keyword.t
  def deprecate(node, options \\ []) do
    node
    |> Keyword.put(:deprecation, struct(Type.Deprecation, options))
  end

  @doc "Add a non-null constraint to a type"
  @spec non_null(atom) :: Type.NonNull.t
  def non_null(type) do
    %Type.NonNull{of_type: type}
  end

  @doc "Declare a list of a type"
  @spec list_of(atom) :: Type.List.t
  def list_of(type) do
    %Type.List{of_type: type}
  end

  @doc """
  Define a set of arguments.

  Each value defines an argument.

  ## Examples

  The following:

  ```
  args(
    active: [type: :boolean, default_value: true, description: "Limit to active projects"],
    category: [type: :string, description: "Limit to category"]
  )
  ```

  Is equivalent to:

  ```
  %{
    active: %Absinthe.Type.Argument{
      name: "active",
      default_value: true,
      description: "Limit to active projects",
      type: :boolean
    },
    category: %Absinthe.Type.Argument{
      name: "category",
      description: "Limit to category",
      type: :string
    }
  }
  ```

  There's a similar convenience function for fields, `fields/1`.

  ## Options

  For information on the options available for an argument, see `Absinthe.Type.Argument.t`.

  """
  @spec args([{atom, Keyword.t}]) :: %{atom => Type.Argument.t}
  def args(definitions) do
    named(Type.Argument, definitions)
  end

  @doc """
  Define a set of fields.

  Each value defines a field.

  ## Examples

  The following:

  ```
  fields(
    item: [
      description: "Get an item by ID",
      type: :item,
      args: args(id: [type: :id]),
      resolve: &MyResolver.Item.resolve/2
    ]
  )
  ```

  Is equivalent to:

  ```
  %{
    item: %Absinthe.Type.FieldDefinition{
      name: "item",
      description: "Get an item by ID"
      type: :string,
      args: %{
        id: %Absinthe.Type.Argument{
          name: "id"
          type: :id
         }
      },
      resolve: &MyResolver.Item.resolve/2
    }
  }
  ```

  Note the use of `args/1`; it is a similar convenience function.

  ## Options

  For information on the options available for a field, see `Absinthe.Type.FieldDefintion.t`.

  """
  @spec fields([{atom, Keyword.t}]) :: %{atom => Type.FieldDefinition.t}
  def fields(definitions) do
    named(Type.FieldDefinition, definitions)
  end

  @doc false
  defp named(mod, definitions) do
    definitions
    |> Enum.into(%{}, fn ({identifier, definition}) ->
      {
        identifier,
        struct(mod, [{:name, identifier |> to_string} | definition])
      }
    end)
  end

end
