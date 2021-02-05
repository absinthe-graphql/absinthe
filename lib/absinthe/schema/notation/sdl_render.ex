defmodule Absinthe.Schema.Notation.SDL.Render do
  @moduledoc false
  import Inspect.Algebra

  alias Absinthe.Blueprint

  @line_width 120

  def inspect(term, %{pretty: true}) do
    term
    |> render()
    |> concat(line())
    |> format(@line_width)
    |> to_string
  end

  def inspect(term, options) do
    Inspect.Any.inspect(term, options)
  end

  @skip_modules [
    Absinthe.Phase.Schema.Introspection,
    Absinthe.Type.BuiltIns.Directives,
    Absinthe.Type.BuiltIns.Scalars,
    Absinthe.Type.BuiltIns.Introspection
  ]
  defp render(bp, type_definitions \\ [])

  defp render(%Blueprint{} = bp, _) do
    %{
      schema_definitions: [
        %Blueprint.Schema.SchemaDefinition{
          type_definitions: type_definitions,
          directive_definitions: directive_definitions,
          schema_declaration: schema_declaration
        }
      ]
    } = bp

    schema_declaration =
      schema_declaration ||
        %{
          query: Enum.find(type_definitions, &(&1.identifier == :query)),
          mutation: Enum.find(type_definitions, &(&1.identifier == :mutation)),
          subscription: Enum.find(type_definitions, &(&1.identifier == :subscription)),
          description: Enum.find(type_definitions, &(&1.identifier == :__schema)).description
        }

    directive_definitions =
      directive_definitions
      |> Enum.reject(&(&1.module in @skip_modules))

    all_type_definitions =
      type_definitions
      |> Enum.reject(&(&1.__struct__ == Blueprint.Schema.SchemaDeclaration))

    types_to_render =
      all_type_definitions
      |> Enum.reject(&(&1.module in @skip_modules))
      |> Enum.filter(& &1.__private__[:__absinthe_referenced__])

    ([schema_declaration] ++ directive_definitions ++ types_to_render)
    |> Enum.map(&render(&1, all_type_definitions))
    |> Enum.reject(&(&1 == empty()))
    |> join([line(), line()])
  end

  defp render(%Blueprint.Schema.SchemaDeclaration{} = schema, type_definitions) do
    block(
      concat([
        "schema",
        directives(schema.directives, type_definitions)
      ]),
      render_list(schema.field_definitions, type_definitions)
    )
    |> description(schema.description)
  end

  defp render(
         %{
           query: query_type,
           mutation: mutation_type,
           subscription: subscription_type,
           description: description
         },
         _type_definitions
       ) do
    schema_type_docs =
      [
        query_type && concat("query: ", string(query_type.name)),
        mutation_type && concat("mutation: ", string(mutation_type.name)),
        subscription_type && concat("subscription: ", string(subscription_type.name))
      ]
      |> Enum.reject(&is_nil/1)
      |> join([line()])

    block(
      "schema",
      schema_type_docs
    )
    |> description(description)
  end

  @adapter Absinthe.Adapter.LanguageConventions
  defp render(%Blueprint.Schema.InputValueDefinition{} = input_value, type_definitions) do
    concat([
      string(@adapter.to_external_name(input_value.name, :argument)),
      ": ",
      render(input_value.type, type_definitions),
      default(input_value.default_value_blueprint),
      directives(input_value.directives, type_definitions)
    ])
    |> description(input_value.description)
  end

  defp render(%Blueprint.Schema.FieldDefinition{} = field, type_definitions) do
    concat([
      string(@adapter.to_external_name(field.name, :field)),
      arguments(field.arguments, type_definitions),
      ": ",
      render(field.type, type_definitions),
      directives(field.directives, type_definitions)
    ])
    |> description(field.description)
  end

  defp render(%Blueprint.Schema.ObjectTypeDefinition{} = object_type, type_definitions) do
    block(
      "type",
      concat([
        string(object_type.name),
        implements(object_type, type_definitions),
        directives(object_type.directives, type_definitions)
      ]),
      render_list(object_type.fields, type_definitions)
    )
    |> description(object_type.description)
  end

  defp render(%Blueprint.Schema.InputObjectTypeDefinition{} = input_object_type, type_definitions) do
    block(
      concat([
        "input ",
        string(input_object_type.name),
        directives(input_object_type.directives, type_definitions)
      ]),
      render_list(input_object_type.fields, type_definitions)
    )
    |> description(input_object_type.description)
  end

  defp render(%Blueprint.Schema.UnionTypeDefinition{} = union_type, type_definitions) do
    types =
      Enum.map(union_type.types, fn
        identifier when is_atom(identifier) ->
          render(%Blueprint.TypeReference.Identifier{id: identifier}, type_definitions)

        %Blueprint.TypeReference.Name{} = ref ->
          render(ref, type_definitions)

        %Blueprint.TypeReference.Identifier{} = ref ->
          render(ref, type_definitions)
      end)

    concat([
      "union ",
      string(union_type.name),
      directives(union_type.directives, type_definitions),
      " = ",
      join(types, " | ")
    ])
    |> description(union_type.description)
  end

  defp render(%Blueprint.Schema.InterfaceTypeDefinition{} = interface_type, type_definitions) do
    block(
      "interface",
      concat([
        string(interface_type.name),
        implements(interface_type, type_definitions),
        directives(interface_type.directives, type_definitions)
      ]),
      render_list(interface_type.fields, type_definitions)
    )
    |> description(interface_type.description)
  end

  defp render(%Blueprint.Schema.EnumTypeDefinition{} = enum_type, type_definitions) do
    block(
      concat([
        "enum ",
        string(enum_type.name),
        directives(enum_type.directives, type_definitions)
      ]),
      render_list(List.flatten(enum_type.values), type_definitions)
    )
    |> description(enum_type.description)
  end

  defp render(%Blueprint.Schema.EnumValueDefinition{} = enum_value, type_definitions) do
    concat([
      string(enum_value.name),
      directives(enum_value.directives, type_definitions)
    ])
    |> description(enum_value.description)
  end

  defp render(%Blueprint.Schema.ScalarTypeDefinition{} = scalar_type, type_definitions) do
    concat([
      "scalar ",
      string(scalar_type.name),
      directives(scalar_type.directives, type_definitions)
    ])
    |> description(scalar_type.description)
  end

  defp render(%Blueprint.Schema.DirectiveDefinition{} = directive, type_definitions) do
    locations = directive.locations |> Enum.map(&String.upcase(to_string(&1)))

    concat([
      "directive ",
      "@",
      string(directive.name),
      arguments(directive.arguments, type_definitions),
      repeatable(directive.repeatable),
      " on ",
      join(locations, " | ")
    ])
    |> description(directive.description)
  end

  defp render(%Blueprint.Directive{} = directive, type_definitions) do
    concat([
      " @",
      directive.name,
      directive_arguments(directive.arguments, type_definitions)
    ])
  end

  defp render(%Blueprint.Input.Argument{} = argument, _type_definitions) do
    concat([
      argument.name,
      ": ",
      render_value(argument.input_value)
    ])
  end

  defp render(%Blueprint.TypeReference.Name{name: name}, _type_definitions) do
    string(name)
  end

  defp render(%Blueprint.TypeReference.Identifier{id: id}, type_definitions) do
    type = Enum.find(type_definitions, &(&1.identifier == id))

    if type do
      string(type.name)
    else
      all_type_ids = Enum.map(type_definitions, & &1.identifier)

      raise """
      No type found for identifier #{inspect(id)} in #{inspect(all_type_ids)}
      """
    end
  end

  defp render(%Blueprint.TypeReference.List{of_type: of_type}, type_definitions) do
    concat(["[", render(of_type, type_definitions), "]"])
  end

  defp render(%Blueprint.TypeReference.NonNull{of_type: of_type}, type_definitions) do
    concat([render(of_type, type_definitions), "!"])
  end

  defp render(nil, _) do
    raise "Unexpected nil"
  end

  defp render(identifier, type_definitions) when is_atom(identifier) do
    render(%Blueprint.TypeReference.Identifier{id: identifier}, type_definitions)
  end

  # SDL Syntax Helpers

  defp directives([], _) do
    empty()
  end

  defp directives(directives, type_definitions) do
    concat(Enum.map(directives, &render(&1, type_definitions)))
  end

  defp directive_arguments([], _) do
    empty()
  end

  defp directive_arguments(arguments, type_definitions) do
    args = Enum.map(arguments, &render(&1, type_definitions))

    concat([
      "(",
      join(args, ", "),
      ")"
    ])
  end

  defp arguments([], _) do
    empty()
  end

  defp arguments(args, type_definitions) do
    any_descriptions? = Enum.any?(args, & &1.description)

    group(
      glue(
        nest(
          multiline(
            glue(
              "(",
              "",
              render_list(args, type_definitions, ", ")
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
    concat([" = ", render_value(default_value)])
  end

  defp description(docs, nil) do
    docs
  end

  defp description(docs, description) do
    concat([
      render_string_value(description, 0),
      line(),
      docs
    ])
  end

  defp implements(%{interface_blueprints: [], interfaces: []}, _) do
    empty()
  end

  defp implements(interface, type_definitions) do
    interface_names =
      case interface do
        %{interface_blueprints: [], interfaces: identifiers} ->
          Enum.map(identifiers, fn identifier ->
            Enum.find_value(type_definitions, fn
              %{identifier: ^identifier, name: name} -> name
              _ -> nil
            end)
          end)

        %{interface_blueprints: blueprints} ->
          Enum.map(blueprints, & &1.name)
      end

    concat([
      " implements ",
      join(interface_names, " & ")
    ])
  end

  defp repeatable(true), do: " repeatable"
  defp repeatable(_), do: empty()

  # Render Helpers

  defp render_list(items, type_definitions, seperator \\ line())

  # Workaround for `values` macro which temporarily defines
  # values as raw atoms to support dynamic schemas
  defp render_list([first | _] = items, type_definitions, seperator) when is_atom(first) do
    items
    |> Enum.map(
      &%Blueprint.Schema.EnumValueDefinition{
        value: &1,
        name: String.upcase(to_string(&1))
      }
    )
    |> render_list(type_definitions, seperator)
  end

  defp render_list(items, type_definitions, seperator) do
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
      item, :start -> render(item, type_definitions)
      item, acc -> concat([render(item, type_definitions)] ++ splitter ++ [acc])
    end)
  end

  defp render_value(%Blueprint.Input.String{value: value}),
    do: render_string_value(value)

  defp render_value(%Blueprint.Input.RawValue{content: content}),
    do: render_value(content)

  defp render_value(%Blueprint.Input.Value{raw: raw}),
    do: render_value(raw)

  defp render_value(%Blueprint.Input.Null{}),
    do: "null"

  defp render_value(%Blueprint.Input.Object{fields: fields}) do
    default_fields = Enum.map(fields, &render_value/1)
    concat(["{", join(default_fields, ", "), "}"])
  end

  defp render_value(%Blueprint.Input.List{items: items}) do
    default_list = Enum.map(items, &render_value/1)
    concat(["[", join(default_list, ", "), "]"])
  end

  defp render_value(%Blueprint.Input.Field{name: name, input_value: value}),
    do: concat([name, ": ", render_value(value)])

  defp render_value(%{value: value}),
    do: to_string(value)

  defp render_string_value(string, indent \\ 2) do
    string
    |> String.trim()
    |> String.split("\n")
    |> case do
      [string_line] ->
        concat([~s("), escape_string(string_line), ~s(")])

      string_lines ->
        concat(
          nest(
            block_string([~s(""")] ++ string_lines),
            indent,
            :always
          ),
          concat(line(), ~s("""))
        )
    end
  end

  @escaped_chars [?", ?\\, ?/, ?\b, ?\f, ?\n, ?\r, ?\t]

  defp escape_string(string) do
    escape_string(string, [])
  end

  defp escape_string(<<char, rest::binary>>, acc) when char in @escaped_chars do
    escape_string(rest, [acc | escape_char(char)])
  end

  defp escape_string(<<char::utf8, rest::binary>>, acc) do
    escape_string(rest, [acc | <<char::utf8>>])
  end

  defp escape_string(<<>>, acc) do
    to_string(acc)
  end

  defp escape_char(?"), do: [?\\, ?"]
  defp escape_char(?\\), do: [?\\, ?\\]
  defp escape_char(?/), do: [?\\, ?/]
  defp escape_char(?\b), do: [?\\, ?b]
  defp escape_char(?\f), do: [?\\, ?f]
  defp escape_char(?\n), do: [?\\, ?n]
  defp escape_char(?\r), do: [?\\, ?r]
  defp escape_char(?\t), do: [?\\, ?t]

  # Algebra Helpers

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
