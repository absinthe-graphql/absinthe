defmodule SdlRenderTest do
  use ExUnit.Case

  defmodule TestSchema do
    use Absinthe.Schema

    # Working based on import_sdl_test.exs

    @sdl """
    type Query {
      echo: Category
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
      |> double_lines

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
  def render(%{"kind" => "SCALAR", "name" => name}) when name in @builtin do
    empty()
  end

  def render(%{"name" => "__" <> _introspection_type}) do
    empty()
  end

  def render(%{"kind" => "OBJECT", "name" => name, "fields" => fields}) do
    field_lines =
      fields
      |> Enum.map(fn %{"name" => name, "type" => %{"name" => type_name}} = field ->
        concat([name, ": ", type_name])
      end)

    fields =
      block(
        "type",
        name,
        lines(field_lines)
      )
  end

  def render(%{"kind" => "ENUM", "name" => name, "enumValues" => values}) do
    value_names = Enum.map(values, & &1["name"])

    block(
      "enum",
      name,
      lines(value_names)
    )
  end

  def render(type) do
    IO.inspect(type, label: "MISSIN")
    empty()
  end

  def lines(docs) do
    fold_doc(docs, fn doc, acc ->
      concat([doc, line(), acc])
    end)
  end

  def double_lines(docs) do
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
