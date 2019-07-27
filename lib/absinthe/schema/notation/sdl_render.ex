defmodule Absinthe.Schema.Notation.SDL.Render do
  @moduledoc false
  import Inspect.Algebra

  alias Absinthe.Blueprint

  @doc """
  Render SDL
  """
  @line_width 120

  @skip_modules [
    Absinthe.Phase.Schema.Introspection,
    Absinthe.Type.BuiltIns.Directives,
    Absinthe.Type.BuiltIns.Scalars,
    Absinthe.Type.BuiltIns.Introspection
  ]

  def inspect(term) do
    render(term)
    |> concat(line())
    |> format(@line_width)
    |> to_string
  end

  defp render(%Blueprint{
         schema_definitions: [
           %Blueprint.Schema.SchemaDefinition{
             type_definitions: type_definitions,
             directive_definitions: directive_definitions
           }
         ]
       }) do
    {schema_declaration, type_definitions} =
      type_definitions
      |> Enum.reject(&(&1.module in @skip_modules))
      |> Enum.split_with(&(&1.__struct__ == Blueprint.Schema.SchemaDeclaration))
      |> case do
        {[], type_definitions} ->
          # TODO: remove once macro schema has SchemaDeclaration
          schema_definition = %{
            query: Enum.find(type_definitions, &(&1.identifier == :query)),
            mutation: Enum.find(type_definitions, &(&1.identifier == :mutation)),
            subscription: Enum.find(type_definitions, &(&1.identifier == :subscription))
          }

          {[schema_definition], type_definitions}

        {schema_declaration, type_definitions} ->
          {schema_declaration, type_definitions}
      end

    directive_definitions =
      directive_definitions
      |> Enum.reject(&(&1.module in @skip_modules))

    (schema_declaration ++ directive_definitions ++ type_definitions)
    |> Enum.map(&render/1)
    |> Enum.reject(&(&1 == empty()))
    |> join([line(), line()])
  end

  defp render(%Blueprint.Schema.SchemaDeclaration{} = schema) do
    block(
      "schema",
      render_list(schema.field_definitions)
    )
  end

  # TODO: remove once macro schema has SchemaDeclaration
  defp render(%{
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
      |> concat()

    block(
      "schema",
      schema_type_docs
    )
  end

  defp render(%Blueprint.Schema.InputValueDefinition{} = input_value) do
    concat([
      string(input_value.name),
      ": ",
      render(input_value.type),
      default(input_value.default_value_blueprint)
    ])
    |> description(input_value.description)
  end

  @adapter Absinthe.Adapter.LanguageConventions
  defp render(%Blueprint.Schema.FieldDefinition{} = field) do
    concat([
      string(@adapter.to_external_name(field.name, :field)),
      arguments(field.arguments),
      ": ",
      render(field.type)
    ])
    |> deprecated(field.deprecation)
    |> description(field.description)
  end

  defp render(%Blueprint.Schema.ObjectTypeDefinition{} = object_type) do
    block(
      "type",
      concat([
        string(object_type.name),
        implements(object_type.interface_blueprints)
      ]),
      render_list(object_type.fields)
    )
    |> description(object_type.description)
  end

  defp render(%Blueprint.Schema.InputObjectTypeDefinition{} = input_object_type) do
    block(
      "input",
      string(input_object_type.name),
      render_list(input_object_type.fields)
    )
    |> description(input_object_type.description)
  end

  defp render(%Blueprint.Schema.UnionTypeDefinition{} = union_type) do
    possible_type_docs = Enum.map(union_type.types, & &1.name)

    concat([
      "union ",
      string(union_type.name),
      " = ",
      join(possible_type_docs, " | ")
    ])
    |> description(union_type.description)
  end

  defp render(%Blueprint.Schema.InterfaceTypeDefinition{} = interface_type) do
    block(
      "interface",
      string(interface_type.name),
      render_list(interface_type.fields)
    )
    |> description(interface_type.description)
  end

  defp render(%Blueprint.Schema.EnumTypeDefinition{} = enum_type) do
    block(
      "enum",
      string(enum_type.name),
      render_list(enum_type.values)
    )
    |> description(enum_type.description)
  end

  defp render(%Blueprint.Schema.EnumValueDefinition{} = enum_value) do
    string(enum_value.name)
    |> deprecated(enum_value.deprecation)
    |> description(enum_value.description)
  end

  defp render(%Blueprint.Schema.ScalarTypeDefinition{} = scalar_type) do
    space("scalar", string(scalar_type.name))
    |> description(scalar_type.description)
  end

  defp render(%Blueprint.Schema.DirectiveDefinition{} = directive) do
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

  defp render(%Blueprint.TypeReference.Name{name: name}) do
    string(name)
  end

  defp render(%Blueprint.TypeReference.List{of_type: of_type}) do
    concat(["[", render(of_type), "]"])
  end

  defp render(%Blueprint.TypeReference.NonNull{of_type: of_type}) do
    concat([render(of_type), "!"])
  end

  defp render(:integer), do: "Int"

  defp render(scalar) when is_atom(scalar) do
    scalar |> to_string |> Macro.camelize()
  end

  defp render_list(items, seperator \\ line()) do
    items = Enum.reject(items, &(&1.module in @skip_modules))

    splitter =
      items
      |> Enum.any?(&(&1.description not in ["", nil]))
      |> case do
        true -> [nest(line(), :reset), line()]
        false -> [seperator]
      end

    items
    |> Enum.reverse()
    |> Enum.reduce(:start, fn
      item, :start -> render(item)
      item, acc -> concat([render(item)] ++ splitter ++ [acc])
    end)
  end

  defp arguments([]) do
    empty()
  end

  defp arguments(args) do
    any_descriptions? = Enum.any?(args, & &1.description)

    group(
      glue(
        nest(
          multiline(
            glue(
              "(",
              "",
              render_list(args, ", ")
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

  defp default(nil) do
    empty()
  end

  defp default(default_value) do
    concat([" = ", render_default(default_value)])
  end

  defp render_default(%Blueprint.Input.String{value: value}),
    do: ~s("#{value}")

  defp render_default(%Blueprint.Input.RawValue{content: content}),
    do: render_default(content)

  defp render_default(%Blueprint.Input.Object{fields: fields}) do
    default_fields = Enum.map(fields, &render_default/1)
    concat(["{", join(default_fields, ", "), "}"])
  end

  defp render_default(%Blueprint.Input.List{items: items}) do
    default_list = Enum.map(items, &render_default/1)
    concat(["[", join(default_list, ", "), "]"])
  end

  defp render_default(%Blueprint.Input.Field{name: name, input_value: value}),
    do: "#{name}: #{render_default(value)}"

  defp render_default(%{value: value}),
    do: to_string(value)

  defp deprecated(docs, nil) do
    docs
  end

  defp deprecated(docs, %{reason: nil}) do
    space(docs, "@deprecated")
  end

  defp deprecated(docs, %{reason: reason}) do
    concat([
      space(docs, "@deprecated"),
      "(",
      "reason: ",
      deprecated_reason(reason),
      ")"
    ])
  end

  defp deprecated_reason(reason) do
    reason
    |> String.trim()
    |> String.split("\n")
    |> case do
      [reason] ->
        concat([~s("), reason, ~s(")])

      reason_lines ->
        concat(
          nest(
            block_string([~s(""")] ++ reason_lines),
            2,
            :always
          ),
          concat(line(), ~s("""))
        )
    end
  end

  defp description(docs, nil) do
    docs
  end

  defp description(docs, description) do
    description
    |> String.trim()
    |> String.split("\n")
    |> case do
      [description] ->
        [~s("), description, ~s("), line(), docs]

      description_lines ->
        [block_string([~s(""")] ++ description_lines ++ [~s(""")]), line(), docs]
    end
    |> concat()
  end

  defp implements([]) do
    empty()
  end

  defp implements(interface_types) do
    interface_names = Enum.map(interface_types, & &1.name)

    concat([
      " implements ",
      join(interface_names, " & ")
    ])
  end

  defp multiline(docs, true) do
    force_unfit(docs)
  end

  defp multiline(docs, false) do
    docs
  end

  defp block(kind, name, docs) do
    glue(
      kind,
      block(name, docs)
    )
  end

  defp block(name, docs) do
    glue(
      name,
      group(
        glue(
          nest(
            force_unfit(
              glue(
                "{",
                "",
                docs
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

  defp block_string([string]) do
    string(string)
  end

  defp block_string([string | rest]) do
    string
    |> string()
    |> concat(block_string_line(rest))
    |> concat(block_string(rest))
  end

  defp block_string_line(["", _ | _]), do: nest(line(), :reset)
  defp block_string_line(_), do: line()

  def join(docs, joiner) do
    fold_doc(docs, fn doc, acc ->
      concat([doc, concat(List.wrap(joiner)), acc])
    end)
  end
end
