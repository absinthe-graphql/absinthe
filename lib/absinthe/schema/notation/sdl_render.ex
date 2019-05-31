defmodule Absinthe.Schema.Notation.SDL.Render do
  @moduledoc false
  import Inspect.Algebra
  alias Absinthe.Blueprint.Schema

  @doc """
  Render SDL
  """
  @line_width 120

  @builtin_scalars ["String", "Int", "Float", "Boolean", "ID"]
  @builtin_directives ["skip", "include"]

  def from_introspection(%{
        "__schema" =>
          %{
            "directives" => directives,
            "types" => types
          } = schema
      }) do
    [schema | directives ++ types]
    |> Enum.map(&render/1)
    |> Enum.reject(&(&1 == empty()))
    |> join([line(), line()])
    |> concat(line())
    |> format(@line_width)
    |> to_string
  end

  def from_blueprint(
        %Absinthe.Blueprint{
          schema_definitions: [
            %Absinthe.Blueprint.Schema.SchemaDefinition{
              type_definitions: type_definitions,
              directive_definitions: directive_definitions
            }
          ]
        } = blueprint
      ) do
    query_type = Enum.find(type_definitions, &(&1.identifier == :query))
    mutation_type = Enum.find(type_definitions, &(&1.identifier == :mutation))
    subscription_type = Enum.find(type_definitions, &(&1.identifier == :subscription))
    schema = %{query: query_type, mutation: mutation_type, subscription: subscription_type}

    IO.inspect(blueprint)

    # [schema | directives ++ types]
    [schema | directive_definitions]
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

  # Don't render builtin scalar types
  def render(
        %{
          "kind" => "SCALAR",
          "name" => name,
          "description" => _
        } = scalar
      )
      when name in @builtin_scalars do
    empty()
  end

  # schema
  def render(%{
        "queryType" => query_type,
        "mutationType" => mutation_type,
        "subscriptionType" => subscription_type
      }) do
    schema_type_docs =
      [
        query_type && concat("query: ", render(query_type)),
        mutation_type && concat("query: ", render(mutation_type)),
        subscription_type && concat("query: ", render(subscription_type))
      ]
      |> Enum.reject(&is_nil/1)

    block(
      "schema",
      schema_type_docs
    )
  end

  def render(
        %{
          query: query_type,
          mutation: mutation_type,
          subscription: subscription_type
        } = schema_types
      ) do
    schema_type_docs =
      [
        query_type && concat("query: ", string(query_type.name)),
        mutation_type && concat("mutation: ", string(mutation_type.name)),
        subscription_type && concat("subscription: ", string(subscription_type.name))
      ]
      |> Enum.reject(&is_nil/1)

    block(
      "schema",
      schema_type_docs
    )
  end

  # ARGUMENT
  def render(%{
        "defaultValue" => default_value,
        "name" => name,
        "description" => description,
        "type" => arg_type
      }) do
    concat([
      string(name),
      ": ",
      render(arg_type),
      default(default_value)
    ])
    |> description(description)
  end

  def render(%Schema.InputValueDefinition{} = input_value) do
    concat([
      string(input_value.name),
      ": ",
      render(input_value.type),
      default(input_value.default_value)
    ])
    |> description(input_value.description)
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
    concat([
      string(name),
      arguments(args),
      ": ",
      render(field_type)
    ])
    |> deprecated(is_deprecated, deprecation_reason)
    |> description(description)
  end

  # OBJECT
  def render(%{
        "kind" => "OBJECT",
        "name" => name,
        "description" => description,
        "fields" => fields,
        "interfaces" => interfaces
      }) do
    block(
      "type",
      concat([
        string(name),
        implements(interfaces)
      ]),
      Enum.map(fields, &render/1)
    )
    |> description(description)
  end

  # INPUT_OBJECT
  def render(%{
        "kind" => "INPUT_OBJECT",
        "name" => name,
        "description" => description,
        "inputFields" => input_fields
      }) do
    block(
      "input",
      string(name),
      Enum.map(input_fields, &render/1)
    )
    |> description(description)
  end

  # UNION
  def render(%{
        "kind" => "UNION",
        "name" => name,
        "description" => description,
        "possibleTypes" => possible_types
      }) do
    possible_type_docs = Enum.map(possible_types, & &1["name"])

    concat([
      "union ",
      string(name),
      " = ",
      join(possible_type_docs, " | ")
    ])
    |> description(description)
  end

  # INTERFACE
  def render(%{
        "kind" => "INTERFACE",
        "name" => name,
        "description" => description,
        "fields" => fields
      }) do
    block(
      "interface",
      string(name),
      Enum.map(fields, &render/1)
    )
    |> description(description)
  end

  # ENUM
  def render(%{
        "kind" => "ENUM",
        "name" => name,
        "description" => description,
        "enumValues" => values
      }) do
    block(
      "enum",
      string(name),
      Enum.map(values, &string(&1["name"]))
    )
    |> description(description)
  end

  # SCALAR
  def render(%{
        "kind" => "SCALAR",
        "name" => name,
        "description" => description
      }) do
    space("scalar", string(name))
    |> description(description)
  end

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
    concat([
      "directive ",
      concat("@", string(name)),
      arguments(args),
      " on ",
      join(locations, " | ")
    ])
    |> description(description)
  end

  def render(%Schema.DirectiveDefinition{} = directive) do
    locations = directive.locations |> Enum.map(&String.upcase(to_string(&1)))

    concat([
      "directive ",
      concat("@", string(directive.name)),
      arguments(directive.arguments),
      " on ",
      join(locations, " | ")
    ])
    |> description(directive.description)
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

  def render(%Absinthe.Blueprint.TypeReference.NonNull{of_type: of_type}) do
    concat([render(of_type), "!"])
  end

  def render(%{"name" => name}) do
    string(name)
  end

  def render(type) when is_atom(type) and type in [:string] do
    to_string(type)
  end

  def arguments([]) do
    empty()
  end

  def arguments(args) do
    arg_docs = Enum.map(args, &render/1)

    any_descriptions? =
      Enum.any?(args, fn
        %{"description" => description} -> description
        %{description: description} -> description
      end)

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

  def description(docs, nil) do
    docs
  end

  def description(docs, description) do
    description
    |> String.contains?("\n")
    |> case do
      true ->
        [join([~s("""), description, ~s(""")], line()), docs]

      false ->
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

  def block(kind, name, doc) do
    glue(
      kind,
      block(name, doc)
    )
  end

  def block(name, doc) do
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
  end

  def join(docs, joiner) do
    fold_doc(docs, fn doc, acc ->
      concat([doc, concat(List.wrap(joiner)), acc])
    end)
  end
end
