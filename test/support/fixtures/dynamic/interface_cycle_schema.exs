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
  # query do
  #   field :foo, :foo
  #   field :quux, :quux
  #   field :span, :spam
  # end

  # object :foo do
  #   field :not_name, :string
  #   interface :named
  #   interface :aged

  #   is_type_of fn _ ->
  #     true
  #   end
  # end

  # object :quux do
  #   field :not_name, :string
  #   interface :foo

  #   is_type_of fn _ ->
  #     true
  #   end
  # end

  # object :spam do
  #   field :name, :string
  #   interface :named
  # end

  # interface :named do
  #   field :name, :string
  # end

  # interface :aged do
  #   field :age, :integer
  # end
end
