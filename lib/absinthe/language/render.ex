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

  defp render(%{value: value}) do
    to_string(value)
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
    group(
      glue(
        nest(
          glue(
            "(",
            "",
            render_list(args, ", ")
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

  defp block(:doc_nil, docs) do
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
    List.foldr(items, :doc_nil, fn
      item, :doc_nil -> render(item)
      item, acc -> concat([render(item)] ++ [separator] ++ [acc])
    end)
  end
end
