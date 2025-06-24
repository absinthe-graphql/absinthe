defmodule Absinthe.Language.Render do
  @moduledoc false
  import Inspect.Algebra
  import Absinthe.Utils.Render

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

  defp render(bp)

  defp render(%Absinthe.Language.Document{} = doc) do
    doc.definitions |> Enum.map(&render/1) |> join([line(), line()])
  end

  defp render(%Absinthe.Language.OperationDefinition{} = op) do
    if op.shorthand do
      concat(operation_definition(op), block(render_list(op.selection_set.selections)))
    else
      glue(
        concat([to_string(op.operation), operation_definition(op)]),
        block(render_list(op.selection_set.selections))
      )
    end
  end

  defp render(%Absinthe.Language.Field{} = field) do
    case field.selection_set do
      nil ->
        field_definition(field)

      selection_set ->
        concat([
          field_definition(field),
          " ",
          block(render_list(selection_set.selections))
        ])
    end
  end

  defp render(%Absinthe.Language.VariableDefinition{} = variable_definition) do
    concat([
      "$",
      variable_definition.variable.name,
      ": ",
      render(variable_definition.type),
      default_value(variable_definition)
    ])
  end

  defp render(%Absinthe.Language.NamedType{} = named_type) do
    named_type.name
  end

  defp render(%Absinthe.Language.NonNullType{} = non_null) do
    concat(render(non_null.type), "!")
  end

  defp render(%Absinthe.Language.Argument{} = argument) do
    concat([argument.name, ": ", render(argument.value)])
  end

  defp render(%Absinthe.Language.Directive{} = directive) do
    concat([" @", directive.name, arguments(directive.arguments)])
  end

  defp render(%Absinthe.Language.FragmentSpread{} = spread) do
    concat(["...", spread.name, directives(spread.directives)])
  end

  defp render(%Absinthe.Language.InlineFragment{} = fragment) do
    concat([
      "...",
      inline_fragment_name(fragment),
      directives(fragment.directives),
      " ",
      block(render_list(fragment.selection_set.selections))
    ])
  end

  defp render(%Absinthe.Language.Variable{} = variable) do
    concat("$", variable.name)
  end

  defp render(%Absinthe.Language.StringValue{value: value}) do
    render_string_value(value)
  end

  defp render(%Absinthe.Language.FloatValue{value: value}) do
    "#{value}"
  end

  defp render(%Absinthe.Language.ObjectField{} = object_field) do
    concat([object_field.name, ": ", render(object_field.value)])
  end

  defp render(%Absinthe.Language.ObjectValue{fields: fields}) do
    fields = fields |> Enum.map(&render(&1)) |> join(", ")

    concat(["{ ", fields, " }"])
  end

  defp render(%Absinthe.Language.NullValue{}) do
    "null"
  end

  defp render(%Absinthe.Language.ListType{type: type}) do
    concat(["[", render(type), "]"])
  end

  defp render(%Absinthe.Language.ListValue{values: values}) do
    values = values |> Enum.map(&render(&1)) |> join(", ")

    concat(["[", values, "]"])
  end

  defp render(%Absinthe.Language.Fragment{} = fragment) do
    concat([
      "fragment ",
      fragment.name,
      " on ",
      fragment.type_condition.name,
      directives(fragment.directives)
    ])
    |> block(render_list(fragment.selection_set.selections))
  end

  # Schema
  defp render(%Absinthe.Language.SchemaDeclaration{} = schema) do
    block(
      concat([
        "schema",
        directives(schema.directives)
      ]),
      render_list(schema.fields)
    )
    |> description(schema.description)
  end

  defp render(%Absinthe.Language.FieldDefinition{} = field) do
    concat([
      field.name,
      arguments(field.arguments),
      ": ",
      render(field.type),
      directives(field.directives)
    ])
    |> description(field.description)
  end

  defp render(%Absinthe.Language.ScalarTypeDefinition{} = scalar_type) do
    concat([
      "scalar ",
      string(scalar_type.name),
      directives(scalar_type.directives)
    ])
    |> description(scalar_type.description)
  end

  defp render(%Absinthe.Language.InputValueDefinition{} = input_value) do
    concat([
      input_value.name,
      ": ",
      render(input_value.type),
      default_value(input_value),
      directives(input_value.directives)
    ])
    |> description(input_value.description)
  end

  defp render(%Absinthe.Language.InterfaceTypeDefinition{} = interface_type) do
    block(
      concat([
        "interface ",
        string(interface_type.name),
        implements(interface_type),
        directives(interface_type.directives)
      ]),
      render_list(interface_type.fields)
    )
    |> description(interface_type.description)
  end

  defp render(%Absinthe.Language.UnionTypeDefinition{} = union_type) do
    case Enum.map(union_type.types, &render/1) do
      [] ->
        concat([
          "union ",
          string(union_type.name),
          directives(union_type.directives)
        ])

      types ->
        concat([
          "union ",
          string(union_type.name),
          directives(union_type.directives),
          " = ",
          join(types, " | ")
        ])
    end
    |> description(union_type.description)
  end

  defp render(%Absinthe.Language.ObjectTypeDefinition{} = object_type) do
    block(
      concat([
        "type ",
        string(object_type.name),
        implements(object_type),
        directives(object_type.directives)
      ]),
      render_list(object_type.fields)
    )
    |> description(object_type.description)
  end

  defp render(%Absinthe.Language.InputObjectTypeDefinition{} = input_object_type) do
    block(
      concat([
        "input ",
        string(input_object_type.name),
        directives(input_object_type.directives)
      ]),
      render_list(input_object_type.fields)
    )
    |> description(input_object_type.description)
  end

  defp render(%Absinthe.Language.DirectiveDefinition{} = directive) do
    locations = directive.locations |> Enum.map(&String.upcase(to_string(&1)))

    concat([
      "directive ",
      "@",
      string(directive.name),
      arguments(directive.arguments),
      repeatable(directive.repeatable),
      " on ",
      join(locations, " | ")
    ])
    |> description(directive.description)
  end

  defp render(%Absinthe.Language.EnumTypeDefinition{} = enum_type) do
    block(
      concat([
        "enum ",
        string(enum_type.name),
        directives(enum_type.directives)
      ]),
      render_list(List.flatten(enum_type.values))
    )
    |> description(enum_type.description)
  end

  defp render(%Absinthe.Language.EnumValueDefinition{} = enum_value) do
    concat([
      string(enum_value.value),
      directives(enum_value.directives)
    ])
    |> description(enum_value.description)
  end

  defp render(%Absinthe.Language.TypeExtensionDefinition{} = extension) do
    concat(
      "extend ",
      render(extension.definition)
    )
  end

  defp render(%{value: value}) do
    to_string(value)
  end

  defp implements(%{interfaces: []}) do
    empty()
  end

  defp implements(interface) do
    interface_names = Enum.map(interface.interfaces, & &1.name)

    concat([
      " implements ",
      join(interface_names, " & ")
    ])
  end

  defp repeatable(true), do: " repeatable"
  defp repeatable(_), do: empty()

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

  defp operation_definition(%{name: nil} = op) do
    case op.variable_definitions do
      [] ->
        concat(
          variable_definitions(op.variable_definitions),
          directives(op.directives)
        )

      _ ->
        operation_definition(%{op | name: ""})
    end
  end

  defp operation_definition(%{name: name} = op) do
    concat([" ", name, variable_definitions(op.variable_definitions), directives(op.directives)])
  end

  defp variable_definitions([]) do
    empty()
  end

  defp variable_definitions(definitions) do
    definitions = Enum.map(definitions, &render(&1))

    concat([
      "(",
      join(definitions, ", "),
      ")"
    ])
  end

  defp field_definition(field) do
    concat([
      field_alias(field),
      field.name,
      arguments(field.arguments),
      directives(field.directives)
    ])
  end

  defp default_value(%{default_value: nil}) do
    empty()
  end

  defp default_value(%{default_value: value}) do
    concat(" = ", render(value))
  end

  defp directives([]) do
    empty()
  end

  defp directives(directives) do
    directives |> Enum.map(&render(&1)) |> join(" ")
  end

  defp inline_fragment_name(%{type_condition: nil}) do
    empty()
  end

  defp inline_fragment_name(%{type_condition: %{name: name}}) do
    " on #{name}"
  end

  defp field_alias(%{alias: nil}) do
    empty()
  end

  defp field_alias(%{alias: alias}) do
    concat(alias, ": ")
  end

  defp arguments([]) do
    empty()
  end

  defp arguments(args) do
    any_descriptions? = Enum.any?(args, &(Map.has_key?(&1, :description) && &1.description))

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

  # Helpers

  defp block(docs) do
    do_block(docs)
  end

  defp block(name, docs) do
    glue(
      name,
      do_block(docs)
    )
  end

  defp do_block(docs) do
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
  end

  defp render_list(items, separator \\ line()) do
    splitter =
      items
      |> Enum.any?(&(Map.get(&1, :description) not in ["", nil]))
      |> case do
        true -> [nest(line(), :reset), line()]
        false -> [separator]
      end

    List.foldr(items, :doc_nil, fn
      item, :doc_nil -> render(item)
      item, acc -> concat([render(item)] ++ splitter ++ [acc])
    end)
  end
end
