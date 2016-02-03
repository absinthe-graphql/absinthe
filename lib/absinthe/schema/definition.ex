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

  defmacro object(identifier, blueprint) do
    Absinthe.Type.Object.build(identifier, expand(blueprint))
  end

  defmacro interface(identifier, blueprint) do
  end

  defmacro input_object(identifier, blueprint) do
  end

  defp expand(ast) do
    Macro.postwalk(ast, fn
      {_, _, _} = node -> Macro.expand(node, __ENV__)
      node -> node
    end)
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
  @spec deprecate(Keyword.t, term) :: Keyword.t
  defmacro deprecate(node, options \\ []) do
    node
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
