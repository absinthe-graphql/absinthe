defmodule Absinthe.Schema.Definition do

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro query(attrs) do
  end

  defmacro mutation(attrs) do
  end

  defmacro object(identifier, attrs) do
    blueprint = Macro.expand(attrs, __CALLER__)
    Absinthe.Type.Object.build(identifier, blueprint)
  end

  defmacro interface(identifier, attrs) do
  end

  defmacro input_object(identifier, attrs) do
  end


  @doc """
  Deprecate a field or argument with an optional reason

  ## Examples

  Wrap around an argument or a field definition
  (of a `Absinthe.Type.InputObject`) to deprecate it:

  ```
  args(
    name: deprecate([type: :string, description: "The person's name"])
    # ...
  )
  ```

  You can also provide a reason:

  ```
  args(
    age: deprecate([type: :integer, description: "The person's age"],
                   reason: "None of your business!")
    # ...
  )
  ```

  Some usage information for deprecations:

  * They make non-null types nullable.
  * Currently use of a deprecated argument/field causes an error to be added to the `:errors` entry of a result.
  """
  @spec deprecate(Keyword.t) :: Keyword.t
  defmacro deprecate(node, options \\ []) do
    IO.inspect(node, options: options)
    quote do: node
  end

  @doc "Add a non-null constraint to a type"
  defmacro non_null(type) do
    quote do: %Absinthe.Type.NonNull{of_type: unquote(type)}
  end

  @doc "Declare a list of a type"
  defmacro list_of(type) do
    quote do: %Absinthe.Type.List{of_type: unquote(type)}
  end

end
