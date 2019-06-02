defmodule Absinthe.Schema.Notation.SDL.Render do
  @moduledoc false
  import Inspect.Algebra

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  @doc """
  Render SDL
  """
  @line_width 120

  @builtin_scalars [:string, :integer, :float, :boolean, :id]
  @builtin_directives [:skip, :include]

  def inspect(term) do
    render(term)
    |> concat(line())
    |> format(@line_width)
    |> to_string
  end

  def render(%Blueprint{
        schema_definitions: [
          %Blueprint.Schema.SchemaDefinition{
            type_definitions: type_definitions,
            directive_definitions: directive_definitions
          }
        ]
      }) do
    # For now, pull out the SchemaDeclaration
    type_definitions =
      type_definitions
      |> Enum.reject(&(&1.__struct__ == Blueprint.Schema.SchemaDeclaration))

    schema_definition = %{
      query: Enum.find(type_definitions, &(&1.identifier == :query)),
      mutation: Enum.find(type_definitions, &(&1.identifier == :mutation)),
      subscription: Enum.find(type_definitions, &(&1.identifier == :subscription))
    }

    [schema_definition | directive_definitions ++ type_definitions]
    |> Enum.map(&render/1)
    |> Enum.reject(&(&1 == empty()))
    |> join([line(), line()])
  end

  # schema

  def render(%{
        query: query_type,
        mutation: mutation_type,
        subscription: subscription_type
      }) do
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

  def render(%Schema.InputValueDefinition{} = input_value) do
    concat([
      string(input_value.name),
      ": ",
      render(input_value.type),
      default(input_value.default_value)
    ])
    |> description(input_value.description)
  end

  def render(%Schema.FieldDefinition{} = field) do
    # adapter = blueprint.adapter || Absinthe.Adapter.LanguageConventions
    adapter = Absinthe.Adapter.LanguageConventions

    concat([
      string(adapter.to_external_name(field.name, :field)),
      arguments(field.arguments),
      ": ",
      render(field.type)
    ])
    |> deprecated(!!field.deprecation, field.deprecation)
    |> description(field.description)
  end

  # Don't render introspection types
  # def render(%Schema.ObjectTypeDefinition{name: "__" <> _introspection_type}) do
  #   empty()
  # end

  # Don't render builtin scalar types
  # def render(%Schema.ObjectTypeDefinition{identifier: identifier})
  #     when identifier in @builtin_scalars do
  #   empty()
  # end

  def render(%Schema.ObjectTypeDefinition{} = object_type) do
    block(
      "type",
      concat([
        string(object_type.name),
        implements(object_type.interface_types)
      ]),
      Enum.map(object_type.fields, &render/1)
    )
    |> description(object_type.description)
  end

  def render(%Schema.InputObjectTypeDefinition{} = input_object_type) do
    block(
      "input",
      string(input_object_type.name),
      Enum.map(input_object_type.fields, &render/1)
    )
    |> description(input_object_type.description)
  end

  def render(%Schema.UnionTypeDefinition{} = union_type) do
    possible_type_docs = Enum.map(union_type.types, & &1.name)

    concat([
      "union ",
      string(union_type.name),
      " = ",
      join(possible_type_docs, " | ")
    ])
    |> description(union_type.description)
  end

  def render(%Blueprint.Schema.InterfaceTypeDefinition{} = interace_type) do
    block(
      "interface",
      string(interace_type.name),
      Enum.map(interace_type.fields, &render/1)
    )
    |> description(interace_type.description)
  end

  def render(%Blueprint.Schema.EnumTypeDefinition{} = enum_type) do
    block(
      "enum",
      string(enum_type.name),
      Enum.map(enum_type.values, &string(&1.name))
    )
    |> description(enum_type.description)
  end

  def render(%Blueprint.Schema.ScalarTypeDefinition{} = scalar_type) do
    space("scalar", string(scalar_type.name))
    |> description(scalar_type.description)
  end

  # Don't render builtin directives
  # def render(%Schema.DirectiveDefinition{identifier: identifier})
  #     when identifier in @builtin_directives do
  #   empty()
  # end

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

  def render(%Blueprint.TypeReference.Name{name: name}) do
    string(name)
  end

  def render(%Blueprint.TypeReference.List{type_name: type_name}) when is_binary(type_name) do
    concat(["[", string(type_name), "]"])
  end

  def render(%Blueprint.TypeReference.List{of_type: of_type}) do
    concat(["[", render(of_type), "]"])
  end

  def render(%Blueprint.TypeReference.NonNull{type_name: type_name}) when is_binary(type_name) do
    concat([string(type_name), "!"])
  end

  def render(%Blueprint.TypeReference.NonNull{of_type: of_type}) do
    concat([render(of_type), "!"])
  end

  def render(:integer), do: "Int"

  def render(type) when is_atom(type) and type in @builtin_scalars do
    type |> to_string |> String.capitalize()
  end

  def arguments([]) do
    empty()
  end

  def arguments(args) do
    arg_docs = Enum.map(args, &render/1)
    any_descriptions? = Enum.any?(args, & &1.description)

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
    concat([" = ", to_string(default_value)])
  end

  # TODO: take just 2 args & use struct
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

  def deprecated_reason(%{reason: reason}) do
    deprecated_reason(reason)
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

  def implements(interface_types) do
    interface_names = Enum.map(interface_types, & &1.name)

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
