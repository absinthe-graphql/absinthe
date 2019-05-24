defmodule SdlRenderTest do
  use ExUnit.Case

  defmodule TestSchema do
    use Absinthe.Schema

    # Working based on import_sdl_test.exs

    @sdl """
    type Query {
      echo(category: Category!, times: Int): [Category]!
      posts: Post
    }

    type Post {
      title: String!
    }

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
  https://github.com/graphql/graphql-js/blob/master/src/utilities/schemaPrinter.js

  skips:
    - built in scalars.. String Int Float Boolean ID
    - introspection types.. `__Type`

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

    IO.inspect(types)

    type_doc =
      types
      |> Enum.reverse()
      |> Enum.map(&render/1)
      |> Enum.reject(&(&1 == empty()))
      |> join_double_lines

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

  def render(%{"defaultValue" => _, "name" => name, "type" => arg_type} = arg) do
    IO.inspect(arg, label: "ARG")

    concat([
      name,
      ": ",
      render(arg_type)
    ])
  end

  def render(%{"name" => name, "args" => args, "type" => field_type} = field) do
    IO.inspect(field, label: "FIELD")

    arg_docs = Enum.map(args, &render/1)

    concat([
      name,
      join_args(arg_docs),
      ": ",
      render(field_type)
    ])
  end

  def render(%{"kind" => "OBJECT", "name" => name, "fields" => fields}) do
    field_docs = Enum.map(fields, &render/1)

    fields =
      block(
        "type",
        name,
        join_lines(field_docs)
      )
  end

  def render(%{"kind" => "ENUM", "name" => name, "enumValues" => values}) do
    value_names = Enum.map(values, & &1["name"])

    block(
      "enum",
      name,
      join_lines(value_names)
    )
  end

  def render(type) do
    IO.inspect(type, label: "MISSIN")
    empty()
  end

  def join_args([]) do
    empty()
  end

  def join_args(docs) do
    concat([
      "(",
      fold_doc(docs, fn doc, acc ->
        concat([doc, ", ", acc])
      end),
      ")"
    ])
  end

  def join_lines(docs) do
    fold_doc(docs, fn doc, acc ->
      concat([doc, line(), acc])
    end)
  end

  def join_double_lines(docs) do
    fold_doc(docs, fn doc, acc ->
      concat([doc, line(), line(), acc])
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
