defmodule Absinthe.Schema.Notation.SDL.Render do
  @moduledoc false
  import Inspect.Algebra

  @doc """
  Render SDL
  """
  @line_width 120

  def from_introspection(%{"__schema" => schema}) do
    %{
      "directives" => directives,
      "types" => types,
      "queryType" => _query_type,
      "mutationType" => _mutation_type,
      "subscriptionType" => _subscription_type
    } = schema

    (directives ++ types)
    |> Enum.map(&render/1)
    |> Enum.reject(&(&1 == empty()))
    |> join([line(), line()])
    |> concat(line())
    |> format(@line_width)
    |> to_string
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

  # ARGUMENT
  def render(%{
        "defaultValue" => default_value,
        "name" => name,
        "description" => description,
        "type" => arg_type
      }) do
    description(
      description,
      concat([
        string(name),
        ": ",
        render(arg_type),
        default(default_value)
      ])
    )
  end

  # FIELD
  def render(%{
        "name" => name,
        "description" => description,
        "args" => args,
        "isDeprecated" => is_deprecated,
        "deprecationReason" => deprecation_reason,
        "type" => field_type
      }) do
    description(
      description,
      deprecated(
        concat([
          string(name),
          arguments(args),
          ": ",
          render(field_type)
        ]),
        is_deprecated,
        deprecation_reason
      )
    )
  end

  def render(%{
        "kind" => "OBJECT",
        "name" => name,
        "description" => description,
        "fields" => fields,
        "interfaces" => interfaces
      }) do
    description(
      description,
      block(
        "type",
        concat([
          string(name),
          implements(interfaces)
        ]),
        Enum.map(fields, &render/1)
      )
    )
  end

  def render(%{
        "kind" => "INPUT_OBJECT",
        "name" => name,
        "description" => description,
        "inputFields" => input_fields
      }) do
    description(
      description,
      block(
        "input",
        string(name),
        Enum.map(input_fields, &render/1)
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

    description(
      description,
      concat([
        "union ",
        string(name),
        " = ",
        join(possible_type_docs, " | ")
      ])
    )
  end

  def render(%{
        "kind" => "INTERFACE",
        "name" => name,
        "description" => description,
        "fields" => fields
      }) do
    description(
      description,
      block(
        "interface",
        string(name),
        Enum.map(fields, &render/1)
      )
    )
  end

  def render(%{
        "kind" => "ENUM",
        "name" => name,
        "description" => description,
        "enumValues" => values
      }) do
    description(
      description,
      block(
        "enum",
        string(name),
        Enum.map(values, &string(&1["name"]))
      )
    )
  end

  def render(%{
        "kind" => "SCALAR",
        "name" => name,
        "description" => description
      }) do
    description(
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

  # DIRECTIVE
  def render(%{
        "name" => name,
        "description" => description,
        "args" => args,
        "locations" => locations
      }) do
    description(
      description,
      concat([
        "directive ",
        concat("@", string(name)),
        arguments(args),
        " on ",
        join(locations, " | ")
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

  def arguments([]) do
    empty()
  end

  def arguments(args) do
    arg_docs = Enum.map(args, &render/1)
    any_descriptions? = Enum.any?(args, & &1["description"])

    group(
      glue(
        nest(
          multiline(
            glue(
              "(",
              "",
              fold_doc(arg_docs, &glue(&1, ", ", &2))
            ),
            any_descriptions?
          ),
          2,
          :break
        ),
        "",
        ")"
      )
    )
  end

  def default(nil) do
    empty()
  end

  def default(default_value) do
    concat([" = ", default_value])
  end

  def deprecated(docs, true, nil) do
    space(docs, "@deprecated")
  end

  def deprecated(docs, true, reason) do
    concat([
      space(docs, "@deprecated"),
      "(",
      "reason: ",
      deprecated_reason(reason),
      ")"
    ])
  end

  def deprecated(docs, _deprecated, _reason) do
    docs
  end

  def deprecated_reason(reason) do
    reason
    |> String.trim()
    |> String.split("\n")
    |> case do
      [reason] ->
        concat([~s("), reason, ~s(")])

      reason ->
        glue(
          nest(
            glue(
              ~s("""),
              "",
              fold_doc(reason, &glue(&1, "", &2))
            ),
            2,
            :always
          ),
          ~s(""")
        )
    end
  end

  def description(nil, docs) do
    docs
  end

  def description(description, docs) do
    if String.contains?(description, "\n") do
      [join([~s("""), description, ~s(""")], line()), docs]
    else
      [concat([~s("), description, ~s(")]), docs]
    end
    |> join(line())
  end

  def implements([]) do
    empty()
  end

  def implements(interfaces) do
    interface_names = Enum.map(interfaces, & &1["name"])

    concat([
      " implements ",
      join(interface_names, ", ")
    ])
  end

  def multiline(docs, true) do
    force_unfit(docs)
  end

  def multiline(docs, false) do
    docs
  end

  def join(docs, joiner) do
    fold_doc(docs, fn doc, acc ->
      concat([doc, concat(List.wrap(joiner)), acc])
    end)
  end
end
