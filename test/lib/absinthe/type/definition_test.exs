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
    assert %{reference: %{module: Fixtures, identifier: :article, name: "Article"}} = Fixtures.__absinthe_info__(:types)[:article]
  end

  it "defines a query only schema" do

    blog_schema = QuerySchema.schema

    assert blog_schema.query.name == Fixtures.query.name

    article_field = Type.Object.field(Fixtures.query, :article)
    assert article_field
    assert article_field.name == "article"
    article_schema_type = Schema.lookup_type(blog_schema, article_field.type)
    assert article_schema_type == Fixtures.__absinthe_info__(:types)[:article]
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
    assert blog_schema.mutation.name == Fixtures.mutation.name

    write_mutation = Type.Object.field(Fixtures.mutation, :write_article)
    assert write_mutation
    assert write_mutation.name == "write_article"
    schema_type = Schema.lookup_type(blog_schema, write_mutation.type)
    assert schema_type.name == "Article"
  end

  defmodule EnumSchema do
    use Absinthe.Schema
    alias Absinthe.Type

    def query do
      %Type.Object{
        fields: fields(
          channel: [
            description: "The active color channel"
          ]
        )
      }
    end

    @absinthe :type
    def color_channel do
      %Absinthe.Type.Enum{
        description: "The selected color channel",
        values: values(
          red: [
            description: "Color Red",
            value: :r
          ],
          green: [
            description: "Color Green",
            value: :g
          ],
          blue: [
            description: "Color Blue",
            value: :b
          ],
          alpha: deprecate([
            description: "Alpha Channel",
            value: :a
          ], reason: "We no longer support opacity settings")
        )
      }
    end

    @absinthe :type
    def color_channel2 do
      %Absinthe.Type.Enum{
        description: "The selected color channel",
        values: values(
          red: [
            description: "Color Red"
          ],
          green: [
            description: "Color Green"
          ],
          blue: [
            description: "Color Blue"
          ],
          alpha: deprecate([
            description: "Alpha Channel"
          ], reason: "We no longer support opacity settings")
        )
      }
    end

    @absinthe :type
    def color_channel3 do
      %Absinthe.Type.Enum{
        description: "The selected color channel",
        values: values([:red, :green, :blue, :alpha])
      }
    end

  end

  describe "enums" do
    it "can be defined by a map with defined values" do
      type = EnumSchema.__absinthe_info__(:types)[:color_channel]
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "red", value: :r} = type.values[:red]
    end
    it "can be defined by a map without defined values" do
      type = EnumSchema.__absinthe_info__(:types)[:color_channel2]
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "red", value: :red} = type.values[:red]
    end
    it "can be defined by a shorthand list of atoms" do
      type = EnumSchema.__absinthe_info__(:types)[:color_channel3]
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "red", value: :red} = type.values[:red]
    end
  end

end
