defmodule Absinthe.Type.Fixtures do

  use Absinthe.Type
  alias Absinthe.Type

  def blog_image do
    %Type.ObjectType{
      name: "Image",
      fields: fields(
        url: [type: Type.Scalar.string],
        width: [type: Type.Scalar.integer],
        height: [type: Type.Scalar.integer]
      )
    }
  end

  def blog_author do
    %Type.ObjectType{
      name: "Author",
      fields: fields(
        id: [type: Type.Scalar.string],
        name: [type: Type.Scalar.string],
        recent_article: [type: blog_article],
        pic: [
          type: blog_image,
          args: args(
            width: [type: Type.Scalar.integer],
            height: [type: Type.Scalar.integer]
          )
        ]
      )
    }
  end

  def blog_article do
    %Type.ObjectType{
      name: "Article",
      fields: fields(
        id: [type: Type.Scalar.string],
        is_published: [type: Type.Scalar.string],
        author: [type: blog_author],
        title: [type: Type.Scalar.string],
        body: [type: Type.Scalar.string]
      )
    }
  end

  def blog_query do
    %Type.ObjectType{
      name: "Query",
      fields: fields(
        article: [
          type: blog_article,
          args: args(
            id: [type: Type.Scalar.string]
          )
        ],
        feed: [type: %Type.List{of_type: blog_article}]
      )
    }
  end

  def blog_mutation do
    %Type.ObjectType{
      name: "Mutation",
      fields: fields(
        write_article: [type: blog_article]
      )
    }
  end

  def object_type do
    %Type.ObjectType{
      name: "Object",
      is_type_of: fn -> true end
    }
  end

  def interface_type do
    %Type.InterfaceType{name: "Interface"}
  end

  def union_type do
    %Type.Union{name: "Union", types: [object_type]}
  end

  def enum_type do
    %Type.Enum{name: "Enum", values: %{foo: %{}}}
  end

  def input_object_type do
    %Type.InputObjectType{name: "InputObject"}
  end

end
