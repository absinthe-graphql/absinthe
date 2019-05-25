defmodule SdlRenderTest do
  use ExUnit.Case

  defmodule TestSchema do
    use Absinthe.Schema

    @sdl """
    type User {
      name: String!
    }

    "Sort this thing"
    input SorterInput {
      "By this field"
      field: String!
    }

    "One or the other"
    union SearchResult = Post | User

    type Query {
      echo(
        category: Category!
        "The number of times"
        times: Int
      ): [Category!]!
      posts: Post
      search(limit: Int, sort: SorterInput!): [SearchResult]
    }

    \"\"\"
    A submitted post
    Multiline description
    \"\"\"
    type Post {
      title: String!
    }

    "Simple description"
    enum Category {
      NEWS
      OPINION
    }
    """
    import_sdl @sdl
    def sdl, do: @sdl
  end

  import Inspect.Algebra

  @moduledoc """
  https://wehavefaces.net/graphql-shorthand-notation-cheatsheet-17cd715861b6

  https://github.com/graphql/graphql-js/blob/master/src/utilities/schemaPrinter.js

  skips:
    - built in scalars.. String Int Float Boolean ID
    - introspection types.. `__Type`

  issues:
    - schema definition order is not respected?
    - default value is an `inspect`ed blueprint struct

  todo:
    - [ ] interface & implements
    - [ ] custom scalar
    - [ ] directives
    - [ ] schema block
    - [ ] default values (scalar and complex?)
          `foo: Int = 10`
    - [ ] @deprecated

  ```
  schema {

  }

  directives...

  types...

  ```

  """

  test "Algebra exploration" do
    {:ok, %{data: data}} = Absinthe.Schema.introspect(TestSchema)
    %{"__schema" => %{"types" => types}} = data

    IO.inspect(data)

    type_doc =
      types
      |> Enum.reverse()
      |> Enum.map(&render/1)
      |> Enum.reject(&(&1 == empty()))
      |> join_with([line(), line()])

    doc =
      concat(
        type_doc,
        line()
      )

    rendered =
      doc
      |> format(100)
      |> to_string

    IO.puts("")
    IO.puts("-----------")
    IO.puts(rendered)
    IO.puts("-----------")

    assert rendered == TestSchema.sdl()
  end

  @builtin ["String", "Int", "Float", "Boolean", "ID"]

  def render(%{"name" => "__" <> _introspection_type}) do
    empty()
  end

  def render(%{"ofType" => nil, "kind" => "SCALAR", "name" => name}) do
    name
  end

  def render(%{"ofType" => nil, "name" => name}) do
    name
  end

  def render(%{"ofType" => type, "kind" => "LIST"}) do
    concat(["[", render(type), "]"])
  end

  def render(%{"ofType" => type, "kind" => "NON_NULL"}) do
    concat([render(type), "!"])
  end

  def render(%{"kind" => "SCALAR", "name" => name} = thing) when name in @builtin do
    empty()
  end

  def render(%{
        "defaultValue" => _,
        "name" => name,
        "description" => description,
        "type" => arg_type
      }) do
    maybe_description(
      description,
      concat([
        name,
        ": ",
        render(arg_type)
      ])
    )
  end

  def render(%{
        "name" => name,
        "args" => args,
        "type" => field_type
      }) do
    arg_docs = Enum.map(args, &render/1)
    any_descriptions = Enum.any?(args, & &1["description"])

    concat([
      name,
      maybe_args(arg_docs, any_descriptions),
      ": ",
      render(field_type)
    ])
  end

  def render(%{
        "kind" => "OBJECT",
        "name" => name,
        "description" => description,
        "fields" => fields
      }) do
    field_docs = Enum.map(fields, &render/1)

    maybe_description(
      description,
      block(
        "type",
        name,
        join_with(field_docs, line())
      )
    )
  end

  def render(%{
        "kind" => "INPUT_OBJECT",
        "name" => name,
        "description" => description,
        "inputFields" => input_fields
      }) do
    input_field_docs = Enum.map(input_fields, &render/1)

    maybe_description(
      description,
      block(
        "input",
        name,
        join_with(input_field_docs, line())
      )
    )
  end

  def render(%{
        "kind" => "UNION",
        "name" => name,
        "description" => description,
        "possibleTypes" => possible_types
      }) do
    possible_type_docs = Enum.map(possible_types, & &1["name"])

    maybe_description(
      description,
      concat([
        "union",
        " ",
        name,
        " = ",
        join_with(possible_type_docs, " | ")
      ])
    )
  end

  def render(%{
        "kind" => "ENUM",
        "name" => name,
        "description" => description,
        "enumValues" => values
      }) do
    value_names = Enum.map(values, & &1["name"])

    maybe_description(
      description,
      block(
        "enum",
        name,
        join_with(value_names, line())
      )
    )
  end

  def render(type) do
    IO.inspect(type, label: "MISSIN")
    empty()
  end

  def maybe_description(nil, docs), do: docs

  def maybe_description(description, docs) do
    join_with(
      if String.contains?(description, "\n") do
        [
          join_with(["\"\"\"", description, "\"\"\""], line()),
          docs
        ]
      else
        [
          concat(["\"", description, "\""]),
          docs
        ]
      end,
      line()
    )
  end

  def maybe_args([], _) do
    empty()
  end

  # Split to multi-line if there are any descriptions
  def maybe_args(docs, true) do
    concat([
      "(",
      nest(
        concat(
          line(),
          join_with(docs, line())
        ),
        2
      ),
      line(),
      ")"
    ])
  end

  # Stick to single line if there are no descriptions
  def maybe_args(docs, false) do
    concat([
      "(",
      join_with(docs, ", "),
      ")"
    ])
  end

  def join_with(docs, joiner) do
    fold_doc(docs, fn doc, acc ->
      concat([doc, concat(List.wrap(joiner)), acc])
    end)
  end

  def block(kind, name, doc) do
    space(
      space(kind, name),
      concat([
        "{",
        nest(
          concat(line(), doc),
          2
        ),
        line(),
        "}"
      ])
    )
  end
end
