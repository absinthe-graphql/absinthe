defmodule Absinthe.Schema.Prototype do
  @moduledoc """
  Provides the directives available for SDL schema definitions.

  By default, the only directive provided is `@deprecated`, which supports
  a `reason` argument (of GraphQL type `String`). This can be used to
  mark a field

  To add additional schema directives, define your own prototype schema, e.g.:

  ```
  defmodule MyAppWeb.SchemaPrototype do
    use Absinthe.Schema.Prototype

    directive :feature do
      arg :name, non_null(:string)
      on [:interface]
      # Define `expand`, etc.
    end

    # More directives...
  end
  ```

  Then, set it as the prototype for your schema:

  ```
  defmodule MyAppWeb.Schema do
    use Absinthe.Schema

    @prototype_schema MyAppWeb.SchemaPrototype

    # Use `import_sdl`, etc...
  end
  ```
  """
  use __MODULE__.Notation

  defmacro __using__(opts \\ []) do
    __MODULE__.Notation.content(opts)
  end
end
