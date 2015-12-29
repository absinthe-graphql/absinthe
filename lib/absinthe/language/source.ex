defmodule Absinthe.Language.Source do
  # A representation of source input to GraphQL, mostly useful for clients
  # who store GraphQL documents in source files; for example, if the GraphQL
  # input is in a file `Foo.graphql`, it might be useful for name to be
  # `"Foo.graphql"`.
  #
  # ## Examples
  #
  #     @filename "Foo.graphql"
  #     # ...
  #     {:ok, data} = File.read(@filename)
  #     %Absinthe.Language.Source{body: body, name: @filename}
  #     |> Absinthe.run(App.Schema)

  @moduledoc false

  # A query document `body` with source location `name`
  @type t :: %{body: binary, name: binary}

  defstruct body: "", name: "GraphQL"
end
