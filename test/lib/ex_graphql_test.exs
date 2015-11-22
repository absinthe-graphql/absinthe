defmodule ExGraphQLTest do
  use ExSpec, async: true

  it "can run without validation" do
    schema = StarWars.Schema.schema
    query = """
      query HeroNameQuery {
        hero {
          name
        }
      }
    """
    # This does not actually resolve data yet
    assert {:ok, %{"hero" => %{"name" => "R2-D2"}}} = ExGraphQL.run(schema, query, validate: false)
  end

end
