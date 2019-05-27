defmodule SdlRenderTest do
  use ExUnit.Case

  defmodule TestSchema do
    use Absinthe.Schema

    @sdl """
    directive @foo(name: String!) on OBJECT | SCALAR

    type User {
      name: String!
    }

    scalar SweetScalar

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

    \"""
    A submitted post
    Multiline description
    \"""
    type Post {
      old: String
      sweet: SweetScalar
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

  issues:
    - schema definition order is not respected?

  todo:
    - [ ] interface & implements
    - [x] custom scalar
    - [x] directives
    - [x] inspect based arg lines

  todo after fixed:
    - [ ] @deprecated
            @deprecated(reason: "Reason")
    - [ ] schema block
            https://github.com/absinthe-graphql/absinthe/pull/735
    - [ ] default values (scalar and complex?)
            `foo: Int = 10`
  """

  test "group, glue, nest" do
    args = [
      concat(["foo", ": ", "String!"]),
      concat(["bar", ": ", "Int"]),
      concat(["baz", ": ", "Custom"])
    ]

    # force_unfit
    docs =
      concat(
        "argUment",
        group(
          glue(
            nest(
              force_unfit(
                glue(
                  "(",
                  "",
                  fold_doc(args, &glue(&1, ", ", &2))
                )
              ),
              2,
              :break
            ),
            "",
            ")"
          )
        )
      )

    docs
    |> format(100)
    |> IO.puts()

    docs
    |> format(10)
    |> IO.puts()
  end

  test "Algebra exploration" do
    {:ok, %{data: data}} = Absinthe.Schema.introspect(TestSchema)

    %{
      "__schema" => %{
        "types" => types,
        "directives" => directives,
        "queryType" => _query_type,
        "mutationType" => _mutation_type,
        "subscriptionType" => _subscription_type
      }
    } = data

    # IO.inspect(data)

    type_doc =
      types
      |> Enum.reverse()
      |> Enum.map(&render/1)
      |> Enum.reject(&(&1 == empty()))
      |> join_with([line(), line()])

    directive_doc =
      directives
      |> Enum.map(&render/1)
      |> Enum.reject(&(&1 == empty()))
      |> join_with([line(), line()])

    doc =
      concat([
        directive_doc,
        line(),
        line(),
        type_doc,
        line()
      ])

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

  # Don't render introspection types
  def render(%{"name" => "__" <> _introspection_type}) do
    empty()
  end

  def render(%{"ofType" => nil, "kind" => "SCALAR", "name" => name}) do
    string(name)
  end

  def render(%{"ofType" => nil, "name" => name}) do
    string(name)
  end

  def render(%{"ofType" => type, "kind" => "LIST"}) do
    concat(["[", render(type), "]"])
  end

  def render(%{"ofType" => type, "kind" => "NON_NULL"}) do
    concat([render(type), "!"])
  end

  # Don't render builtin scalars
  @builtin_scalars ["String", "Int", "Float", "Boolean", "ID"]
  def render(%{
        "kind" => "SCALAR",
        "name" => name
      })
      when name in @builtin_scalars do
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
        string(name),
        ": ",
        render(arg_type)
      ])
    )
  end

  def render(%{
        "name" => name,
        "args" => args,
        "isDeprecated" => is_deprecated,
        "deprecationReason" => deprecation_reason,
        "type" => field_type
      }) do
    arg_docs = Enum.map(args, &render/1)
    any_descriptions = Enum.any?(args, & &1["description"])

    maybe_deprecated(
      concat([
        string(name),
        arguments(arg_docs, any_descriptions),
        ": ",
        render(field_type)
      ]),
      is_deprecated,
      deprecation_reason
    )
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
        string(name),
        field_docs
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
        string(name),
        input_field_docs
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
        string(name),
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
        string(name),
        value_names
      )
    )
  end

  def render(%{
        "kind" => "SCALAR",
        "name" => name,
        "description" => description
      }) do
    maybe_description(
      description,
      space("scalar", string(name))
    )
  end

  @builtin_directives ["skip", "include"]
  def render(%{
        "name" => name,
        "locations" => _
      })
      when name in @builtin_directives do
    empty()
  end

  def render(%{
        "name" => name,
        "description" => description,
        "args" => args,
        "locations" => locations
      }) do
    arg_docs = Enum.map(args, &render/1)
    any_descriptions = Enum.any?(args, & &1["description"])

    maybe_description(
      description,
      concat([
        "directive",
        " ",
        concat("@", string(name)),
        arguments(arg_docs, any_descriptions),
        " on ",
        join_with(locations, " | ")
      ])
    )
  end

  def render(type) do
    IO.inspect(type, label: "MISSIN")
    empty()
  end

  def block(kind, name, doc) do
    glue(
      kind,
      glue(
        name,
        group(
          glue(
            nest(
              force_unfit(
                glue(
                  "{",
                  "",
                  fold_doc(doc, &glue(&1, "", &2))
                )
              ),
              2,
              :always
            ),
            "",
            "}"
          )
        )
      )
    )
  end

  def arguments([], _) do
    empty()
  end

  def arguments(docs, descriptions?) do
    group(
      glue(
        nest(
          maybe_force_multiline(
            glue(
              "(",
              "",
              fold_doc(docs, &glue(&1, ", ", &2))
            ),
            descriptions?
          ),
          2,
          :break
        ),
        "",
        ")"
      )
    )
  end

  def maybe_deprecated(docs, true, nil) do
    space(docs, "@deprecated")
  end

  def maybe_deprecated(docs, _deprecated, _reason) do
    docs
  end

  def maybe_description(nil, docs) do
    docs
  end

  def maybe_description(description, docs) do
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
    end
    |> join_with(line())
  end

  def maybe_force_multiline(docs, true) do
    force_unfit(docs)
  end

  def maybe_force_multiline(docs, false) do
    docs
  end

  def join_with(docs, joiner) do
    fold_doc(docs, fn doc, acc ->
      concat([doc, concat(List.wrap(joiner)), acc])
    end)
  end
end
