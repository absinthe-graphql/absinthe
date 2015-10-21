defmodule Type.Fixtures do

  alias ExGraphQL.Type

  def blog_image do
    %Type.Object{name: "Image",
                 fields: %{url: %{type: Type.Scalar.string},
                           width: %{type: Type.Scalar.integer},
                           height: %{type: Type.Scalar.integer}}}
  end

  def blog_author do
    %Type.Object{name: "Author",
                  fields: fn -> %{
                                id: %{type: Type.Scalar.string},
                                name: %{type: Type.Scalar.string},
                                pic: %{args: %{width: %{type: Type.Scalar.integer},
                                               height: %{type: Type.Scalar.integer}},
                                       type: blog_image},
                                recent_article: %{type: blog_article}}
                  end}
  end

  def blog_article do
    %Type.Object{name: "Article",
                 fields: %{id: %{type: Type.Scalar.string},
                           isPublished: %{type: Type.Scalar.boolean},
                           author: %{type: blog_author},
                           title: %{type: Type.Scalar.string},
                           body: %{type: Type.Scalar.string}}}
  end

  def blog_query do
    %Type.Object{name: "Query",
                 fields: %{article: %{args: %{id: %{type: Type.Scalar.string}},
                                      type: blog_article},
                           feed: %{type: %Type.List{of_type: blog_article}}}}
  end

  def blog_mutation do
    %Type.Object{name: "Mutation",
                 fields: %{writeArticle: %{type: blog_article}}}
  end

  def object_type do
    %Type.Object{name: "Object",
                  is_type_of: fn ->
                    true
                  end}
  end

  def interface_type do
    %Type.Interface{name: "Interface"}
  end

  def union_type do
    %Type.Union{name: "Union", types: [object_type]}
  end

  def enum_type do
    %Type.Enum{name: "Enum", values: %{foo: %{}}}
  end

  def input_object_type do
    %Type.InputObject{name: "InputObject"}
  end

end
