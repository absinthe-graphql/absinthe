defmodule Absinthe.Type.Union do

  @moduledoc """
  A unions is an abstract type made up of multiple possible concrete types.

  No common fields are declared in a union. Compare to `Absinthe.Type.Interface`.

  Because it's necessary for the union to determine the concrete type of a
  resolved object, you must either:

  * Provide a `:resolve_type` function on the union
  * Provide a `:is_type_of` function on each possible concrete type

  ```
  @absinthe :type
  def search_result do
    %Type.Union{
      description: "A search result that can be a person or business",
      types: [:person, :business],
      resolve_type: fn
        %{age: _}, _ -> {:ok, :person}
        %{employee_count: _}, _ -> {:ok, :business}
        _ -> :error
      end
    }
  end
  ```

  * `:name` - The name of the union type. Should be a TitleCased `binary`. Set automatically when using `@absinthe :type` from `Absinthe.Type.Definitions`.
  * `:description` - A nice description for introspection.
  * `:types` - The list of possible types.
  * `:resolve_type` - A function used to determine the concrete type of a resolved object. See also `Absinthe.Type.Object`'s `:is_type_of`.

  The `:resolve_type` function will be passed two arguments; the object whose type needs to be identified, and the `Absinthe.Execution` struct providing the full execution context.

  The `:reference` key is for internal use.
  """

  use Absinthe.Introspection.Kind

  alias Absinthe.Type

  @type t :: %{name: binary,
               description: binary,
               types: [Absinthe.Type.t],
               resolve_type: ((any, Absinthe.Execution.t) -> atom | nil),
               reference: Type.Reference.t}

  defstruct name: nil, description: nil, resolve_type: nil, types: [], reference: nil

  def build(identifier, blueprint) do
    quote do
      %unquote(__MODULE__){
        name: unquote(blueprint[:name]),
        types: unquote(blueprint[:types]) || [],
        resolve_type: unquote(blueprint[:resolve_type]),
        description: @absinthe_doc,
        reference: %{
          module: __MODULE__,
          identifier: unquote(identifier),
          location: %{
            file: __ENV__.file,
            line: __ENV__.line
          }
        }
      }
    end
  end

  @doc false
  def member?(%{types: types}, type) do
    types
    |> Enum.member?(type)
  end

  @doc false
  @spec resolve_type(t, any, Execution.Field.t) :: Type.t | nil
  def resolve_type(%{resolve_type: nil, types: types}, obj, %{schema: schema}) do
    Enum.find(types, fn
      %{is_type_of: nil} ->
        false
      type ->
        case Schema.lookup_type(schema, type) do
          nil ->
            false
          %{is_type_of: nil} ->
            false
          %{is_type_of: check} ->
            check.(obj)
        end
    end)
  end
  def resolve_type(%{resolve_type: resolver}, obj, %{schema: schema} = env) do
    case resolver.(obj, env) do
      nil ->
        nil
      ident when is_atom(ident) ->
        Absinthe.Schema.lookup_type(schema, ident)
    end
  end

end
