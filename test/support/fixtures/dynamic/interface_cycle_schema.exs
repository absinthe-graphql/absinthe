defmodule Absinthe.TestSupport.Schema.InterfaceCycleSchema do
  use Absinthe.Schema

  @sdl """
  schema {
    query: Query
  }

  type Query {
    node: Node
  }

  interface Node implements Named & Node {
    id: ID!
    name: String
  }

  interface Named implements Node & Named {
    id: ID!
    name: String
  }
  """

  import_sdl @sdl
end
