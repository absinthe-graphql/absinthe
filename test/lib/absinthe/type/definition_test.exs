defmodule Absinthe.Type.DefinitionTest do
  use ExSpec, async: true

  alias Absinthe.Schema
  alias Absinthe.Type.Fixtures
  alias Absinthe.Type

  defmodule QuerySchema do
    use Absinthe.Schema, type_modules: [Fixtures]

    def query, do: Fixtures.query
  end

  it "correctly assigns type references" do
    assert %{reference: %{module: Fixtures, identifier: :article, name: "Article"}} = Fixtures.absinthe_types[:article]
  end

  it "defines a query only schema" do

    blog_schema = QuerySchema.schema

    assert blog_schema.query == Fixtures.query

    article_field = Type.Object.field(Fixtures.query, :article)
    assert article_field
    assert article_field.name == "article"
    article_schema_type = Schema.lookup_type(blog_schema, article_field.type)
    assert article_schema_type == Fixtures.absinthe_types[:article]
    assert article_schema_type.name == "Article"

    title_field = Type.Object.field(article_schema_type, :title)
    assert title_field
    title_schema_type = Schema.lookup_type(blog_schema, title_field.type)
    assert title_field.name == "title"
    assert title_schema_type.name == "String"

    author_field = Type.Object.field(article_schema_type, :author)
    author_schema_type = Schema.lookup_type(blog_schema, author_field.type)
    recent_article_field = Type.Object.field(author_schema_type, :recent_article)
    assert recent_article_field.name == "recent_article"
    assert recent_article_field
    recent_article_field_type = Schema.lookup_type(blog_schema, recent_article_field.type)
    assert recent_article_field_type.name == "Article"

    feed_field = Type.Object.field(Fixtures.query, :feed)
    assert feed_field
    assert feed_field.name == "feed"
    feed_schema_type = Schema.lookup_type(blog_schema, feed_field.type)
    assert feed_schema_type.name == "Article"
  end

  defmodule MutationSchema do
    use Absinthe.Schema, type_modules: [Fixtures]

    def query, do: Fixtures.query
    def mutation, do: Fixtures.mutation
  end


  it "defines a mutation schema" do
    blog_schema = MutationSchema.schema
    assert blog_schema.mutation == Fixtures.mutation

    write_mutation = Type.Object.field(Fixtures.mutation, :write_article)
    assert write_mutation
    assert write_mutation.name == "write_article"
    schema_type = Schema.lookup_type(blog_schema, write_mutation.type)
    assert schema_type.name == "Article"
  end

end
