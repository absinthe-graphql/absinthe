defmodule Absinthe.Formatter do
  @moduledoc """
  Formatter task for graphql

  Will format files with the extensions .graphql or .gql

  ## Example
  ```elixir
  Absinthe.Formatter.format("{ version }")
  "{\n  version\n}\n"
  ```


  From Elixir 1.13 onwards the Absinthe.Formatter can be added to
  the formatter as a plugin:

  ```elixir
  # .formatter.exs
  [
    # Define the desired plugins
    plugins: [Absinthe.Formatter],
    # Remember to update the inputs list to include the new extensions
    inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}", "{lib, priv}/**/*.{gql,graphql}"]
  ]
  ```
  """

  def features(_opts) do
    [sigils: [], extensions: [".graphql", ".gql"]]
  end

  def format(contents, _opts \\ []) do
    {:ok, blueprint} = Absinthe.Phase.Parse.run(contents, [])
    inspect(blueprint.input, pretty: true)
  end
end
