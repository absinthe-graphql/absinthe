defmodule Absinthe.Type.Fixtures do

  use Absinthe.Schema
  alias Absinthe.Type

  @absinthe :type
  def image do
    %Type.ObjectType{
      fields: fields(
        url: [type: :string],
        width: [type: :int],
        height: [type: :int]
      )
    }
  end

  @absinthe :type
  def author do
    %Type.ObjectType{
      fields: fields(
        id: [type: :id],
        name: [type: :string],
        recent_article: [type: :article],
        pic: [
          type: :image,
          args: args(
            width: [type: :int],
            height: [type: :int]
          )
        ]
      )
    }
  end

  @absinthe :type
  def article do
    %Type.ObjectType{
      fields: fields(
        id: [type: :string],
        is_published: [type: :string],
        author: [type: :author],
        title: [type: :string],
        body: [type: :string]
      )
    }
  end

  def query do
    %Type.ObjectType{
      name: "Query",
      fields: fields(
        article: [
          type: :article,
          args: args(
            id: [type: :string]
          )
        ],
        feed: [type: list_of(:article)]
      )
    }
  end

  def mutation do
    %Type.ObjectType{
      name: "Mutation",
      fields: fields(
        write_article: [type: :article]
      )
    }
  end

  @absinthe :type
  def object_type do
    %Type.ObjectType{
      is_type_of: fn -> true end
    }
  end

  @absinthe :type
  def interface_type do
    %Type.InterfaceType{}
  end

  @absinthe :type
  def union_type do
    %Type.Union{types: [object_type]}
  end

  @absinthe :type
  def enum_type do
    %Type.Enum{values: %{foo: %{}}}
  end

  @absinthe :type
  def input_object_type do
    %Type.InputObjectType{}
  end

end
