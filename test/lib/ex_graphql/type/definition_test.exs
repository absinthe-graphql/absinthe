defmodule ExGraphQL.Type.DefinitionTest do
  use ExSpec, async: true

  alias ExGraphQL.Type.Fixtures

  use ExGraphQL.Type
  alias ExGraphQL.Type

  it "defines a query only schema" do

    blog_schema = %ExGraphQL.Type.Schema{query: Fixtures.blog_query}

    assert blog_schema.query == Fixtures.blog_query

    article_field = Type.ObjectType.field(Fixtures.blog_query, :article)
    assert article_field
    assert article_field.type == Fixtures.blog_article
    assert article_field.type.name == "Article"
    assert article_field.name == "article"

    title_field = Type.ObjectType.field(article_field.type, :title)
    assert title_field
    assert title_field.name == "title"
    assert title_field.type == ExGraphQL.Type.Scalar.string
    assert title_field.type.name == "String"

    author_field = Type.ObjectType.field(article_field.type, :author)
    recent_article_field = Type.ObjectType.field(author_field.type, :recent_article)
    assert recent_article_field
    assert recent_article_field.type == Fixtures.blog_article

    feed_field = Type.ObjectType.field(Fixtures.blog_query, :feed)
    assert feed_field
    assert feed_field.type.of_type == Fixtures.blog_article
    assert feed_field.name == "feed"

  end

  it "defines a mutation schema" do
    blog_schema = %ExGraphQL.Type.Schema{query: Fixtures.blog_query,
                                         mutation: Fixtures.blog_mutation}
    assert blog_schema.mutation == Fixtures.blog_mutation

    write_mutation = Type.ObjectType.field(Fixtures.blog_mutation, :write_article)
    assert write_mutation
    assert write_mutation.type == Fixtures.blog_article
    assert write_mutation.type.name == "Article"
    assert write_mutation.name == "write_article"
  end

end
