defmodule Type.Fixtures do

  alias ExGraphQL.Type

  def blog_image do
    %Type.ObjectType{name: "Image",
                     fields: %{url: %Type.FieldDefinition{type: Type.Scalar.string},
                               width: %Type.FieldDefinition{type: Type.Scalar.integer},
                               height: %Type.FieldDefinition{type: Type.Scalar.integer}}}
  end

  def blog_author do
    %Type.ObjectType{name: "Author",
                     fields: %{
                       id: %Type.FieldDefinition{type: Type.Scalar.string},
                       name: %Type.FieldDefinition{type: Type.Scalar.string},
                       pic: %Type.FieldDefinition{args: %{width: %Type.Argument{type: Type.Scalar.integer},
                                                          height: %Type.Argument{type: Type.Scalar.integer}},
                                                  type: blog_image},
                       recent_article: %Type.FieldDefinition{type: blog_article}}}
  end

  def blog_article do
    %Type.ObjectType{name: "Article",
                     fields: %{id: %Type.FieldDefinition{type: Type.Scalar.string},
                               isPublished: %Type.FieldDefinition{type: Type.Scalar.boolean},
                               author: %Type.FieldDefinition{type: blog_author},
                               title: %Type.FieldDefinition{type: Type.Scalar.string},
                               body: %Type.FieldDefinition{type: Type.Scalar.string}}}
  end

  def blog_query do
    %Type.ObjectType{name: "Query",
                     fields: %{article: %Type.FieldDefinition{args: %{id: %Type.Argument{type: Type.Scalar.string}},
                                                              type: blog_article},
                               feed: %Type.FieldDefinition{type: %Type.List{of_type: blog_article}}}}
  end

  def blog_mutation do
    %Type.ObjectType{name: "Mutation",
                     fields: %{writeArticle: %Type.FieldDefinition{type: blog_article}}}
  end

  def object_type do
    %Type.ObjectType{name: "Object",
                      is_type_of: fn ->
                        true
                      end}
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
