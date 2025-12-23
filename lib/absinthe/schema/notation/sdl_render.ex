defmodule Absinthe.Schema.Notation.SDL.Render do
  @moduledoc false
  import Inspect.Algebra
  import Absinthe.Utils.Render

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

    directive_definitions =
      directive_definitions
      |> Enum.reject(&(&1.module in @skip_modules))

    types_to_render =
      type_definitions
      |> Enum.reject(&(&1.module in @skip_modules))
      |> Enum.filter(& &1.__private__[:__absinthe_referenced__])

    ([schema_declaration] ++ directive_definitions ++ types_to_render)
    |> Enum.map(&render(&1, type_definitions))
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

  @adapter Absinthe.Adapter.LanguageConventions
  defp render(%Blueprint.Schema.InputValueDefinition{} = input_value, type_definitions) do
    concat([
      string(@adapter.to_external_name(input_value.name, :argument)),
      ": ",
      render(input_value.type, type_definitions),
      default(input_value, type_definitions),
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
      render_input_fields(input_object_type.fields, type_definitions)
    )
    |> description(input_object_type.description)
  end

  defp render(%Blueprint.Schema.UnionTypeDefinition{} = union_type, type_definitions) do
    Enum.map(union_type.types, fn
      identifier when is_atom(identifier) ->
        render(%Blueprint.TypeReference.Identifier{id: identifier}, type_definitions)

      %Blueprint.TypeReference.Name{} = ref ->
        render(ref, type_definitions)

      %Blueprint.TypeReference.Identifier{} = ref ->
        render(ref, type_definitions)
    end)
    |> case do
      [] ->
        concat([
          "union ",
          string(union_type.name),
          directives(union_type.directives, type_definitions)
        ])

      types ->
        concat([
          "union ",
          string(union_type.name),
          directives(union_type.directives, type_definitions),
          " = ",
          join(types, " | ")
        ])
    end
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
    directives =
      Enum.map(directives, fn directive ->
        %{directive | name: Absinthe.Utils.camelize(directive.name, lower: true)}
      end)

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

  defp default(%Blueprint.Schema.FieldDefinition{default_value: nil}, _type_definitions) do
    empty()
  end

  defp default(%Blueprint.Schema.FieldDefinition{default_value: {:ref, _, _}}, _type_definitions) do
    empty()
  end

  defp default(
         %Blueprint.Schema.FieldDefinition{type: type, default_value: default_value},
         type_definitions
       )
       when is_atom(default_value) do
    case find_enum_value_name(type, default_value, type_definitions) do
      {:ok, enum_name} ->
        concat([" = ", string(enum_name)])

      :error ->
        try do
          blueprint_value = Blueprint.Input.parse(default_value)
          concat([" = ", render_value(blueprint_value)])
        rescue
          _ -> empty()
        end
    end
  end

  defp default(
         %Blueprint.Schema.FieldDefinition{default_value: default_value},
         _type_definitions
       )
       when is_binary(default_value) or is_number(default_value) or is_boolean(default_value) or
              is_list(default_value) or is_map(default_value) do
    try do
      blueprint_value = Blueprint.Input.parse(default_value)
      concat([" = ", render_value(blueprint_value)])
    rescue
      _ -> empty()
    end
  end

  defp default(%Blueprint.Schema.FieldDefinition{}, _type_definitions) do
    empty()
  end

  defp default(
         %Blueprint.Schema.InputValueDefinition{
           default_value_blueprint: nil,
           default_value: nil
         },
         _type_definitions
       ) do
    empty()
  end

  defp default(
         %Blueprint.Schema.InputValueDefinition{
           default_value_blueprint: nil,
           default_value: default_value
         },
         _type_definitions
       )
       when not is_nil(default_value) do
    blueprint_value = Blueprint.Input.parse(default_value)
    concat([" = ", render_value(blueprint_value)])
  end

  defp default(
         %Blueprint.Schema.InputValueDefinition{
           default_value_blueprint: default_value_blueprint
         },
         _type_definitions
       )
       when not is_nil(default_value_blueprint) do
    concat([" = ", render_value(default_value_blueprint)])
  end

  defp default(_, _) do
    empty()
  end

  defp find_enum_value_name(type, internal_value, type_definitions) do
    enum_identifier = unwrap_type_identifier(type)

    with enum_def when not is_nil(enum_def) <-
           Enum.find(type_definitions, &(&1.identifier == enum_identifier)),
         %Blueprint.Schema.EnumTypeDefinition{} <- enum_def,
         enum_value when not is_nil(enum_value) <-
           Enum.find(List.flatten(enum_def.values), fn
             %Blueprint.Schema.EnumValueDefinition{value: ^internal_value} -> true
             atom when is_atom(atom) and atom == internal_value -> true
             _ -> false
           end) do
      case enum_value do
        %Blueprint.Schema.EnumValueDefinition{name: name} -> {:ok, name}
        atom when is_atom(atom) -> {:ok, atom |> to_string() |> String.upcase()}
      end
    else
      _ -> :error
    end
  end

  defp unwrap_type_identifier(%Blueprint.TypeReference.NonNull{of_type: inner}),
    do: unwrap_type_identifier(inner)

  defp unwrap_type_identifier(%Blueprint.TypeReference.List{of_type: inner}),
    do: unwrap_type_identifier(inner)

  defp unwrap_type_identifier(%Blueprint.TypeReference.Identifier{id: id}), do: id
  defp unwrap_type_identifier(%Blueprint.TypeReference.Name{name: name}), do: name
  defp unwrap_type_identifier(atom) when is_atom(atom), do: atom
  defp unwrap_type_identifier(_), do: nil

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

  defp render_input_fields(fields, type_definitions) do
    items = Enum.reject(fields, &(&1.module in @skip_modules))

    splitter =
      items
      |> Enum.any?(&(&1.description not in ["", nil]))
      |> case do
        true -> [nest(line(), :reset), line()]
        false -> [line()]
      end

    items
    |> Enum.reverse()
    |> Enum.reduce(:start, fn
      item, :start -> render_input_field(item, type_definitions)
      item, acc -> concat([render_input_field(item, type_definitions)] ++ splitter ++ [acc])
    end)
  end

  defp render_input_field(%Blueprint.Schema.FieldDefinition{} = field, type_definitions) do
    concat([
      string(@adapter.to_external_name(field.name, :field)),
      ": ",
      render(field.type, type_definitions),
      default(field, type_definitions),
      directives(field.directives, type_definitions)
    ])
    |> description(field.description)
  end

  defp render_input_field(%Blueprint.Schema.InputValueDefinition{} = field, type_definitions) do
    concat([
      string(@adapter.to_external_name(field.name, :argument)),
      ": ",
      render(field.type, type_definitions),
      default(field, type_definitions),
      directives(field.directives, type_definitions)
    ])
    |> description(field.description)
  end

  defp render_list(items, type_definitions, separator \\ line())

  # Workaround for `values` macro which temporarily defines
  # values as raw atoms to support dynamic schemas
  defp render_list([first | _] = items, type_definitions, separator) when is_atom(first) do
    items
    |> Enum.map(
      &%Blueprint.Schema.EnumValueDefinition{
        value: &1,
        name: String.upcase(to_string(&1))
      }
    )
    |> render_list(type_definitions, separator)
  end

  defp render_list(items, type_definitions, separator) do
    items = Enum.reject(items, &(&1.module in @skip_modules))

    splitter =
      items
      |> Enum.any?(&(&1.description not in ["", nil]))
      |> case do
        true -> [nest(line(), :reset), line()]
        false -> [separator]
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

  defp render_value(%Blueprint.Input.Field{name: name, input_value: value}) when is_atom(name) do
    concat([string(Atom.to_string(name)), ": ", render_value(value)])
  end

  defp render_value(%Blueprint.Input.Field{name: name, input_value: value})
       when is_binary(name) do
    concat([string(name), ": ", render_value(value)])
  end

  defp render_value(%{value: value}),
    do: to_string(value)

  # Algebra Helpers

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
end
