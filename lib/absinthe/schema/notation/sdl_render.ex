defmodule Absinthe.Schema.Notation.SDL.Render do
  @moduledoc false
  import Inspect.Algebra
  alias Absinthe.Blueprint.Schema

  @doc """
  Render SDL
  """
  @line_width 120

  @builtin_scalar_identifiers [:string, :integer, :float, :boolean, :id]
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
    |> Enum.map(&render(&1, :blueprint))
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
    # For now, pull out the SchemaDeclaration
    type_definitions =
      Enum.reject(
        type_definitions,
        &(&1.__struct__ == Absinthe.Blueprint.Schema.SchemaDeclaration)
      )

    query_type = Enum.find(type_definitions, &(&1.identifier == :query))
    mutation_type = Enum.find(type_definitions, &(&1.identifier == :mutation))
    subscription_type = Enum.find(type_definitions, &(&1.identifier == :subscription))
    schema = %{query: query_type, mutation: mutation_type, subscription: subscription_type}

    # IO.inspect(blueprint)

    [schema | directive_definitions ++ type_definitions]
    |> Enum.map(&render(&1, blueprint))
    |> Enum.reject(&(&1 == empty()))
    |> join([line(), line()])
    |> concat(line())
    |> format(@line_width)
    |> to_string
  end

  # Don't render introspection types
  def render(%{"name" => "__" <> _introspection_type}, _blueprint) do
    empty()
  end

  # Don't render builtin scalar types
  def render(
        %{
          "kind" => "SCALAR",
          "name" => name,
          "description" => _
        },
        _blueprint
      )
      when name in @builtin_scalars do
    empty()
  end

  # schema
  def render(
        %{
          "queryType" => query_type,
          "mutationType" => mutation_type,
          "subscriptionType" => subscription_type
        },
        blueprint
      ) do
    schema_type_docs =
      [
        query_type && concat("query: ", render(query_type, blueprint)),
        mutation_type && concat("query: ", render(mutation_type, blueprint)),
        subscription_type && concat("query: ", render(subscription_type, blueprint))
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
        },
        _blueprint
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
  def render(
        %{
          "defaultValue" => default_value,
          "name" => name,
          "description" => description,
          "type" => arg_type
        },
        blueprint
      ) do
    concat([
      string(name),
      ": ",
      render(arg_type, blueprint),
      default(default_value)
    ])
    |> description(description)
  end

  def render(%Schema.InputValueDefinition{} = input_value, blueprint) do
    concat([
      string(input_value.name),
      ": ",
      render(input_value.type, blueprint),
      default(input_value.default_value)
    ])
    |> description(input_value.description)
  end

  # FIELD
  def render(
        %{
          "name" => name,
          "description" => description,
          "args" => args,
          "isDeprecated" => is_deprecated,
          "deprecationReason" => deprecation_reason,
          "type" => field_type
        },
        blueprint
      ) do
    concat([
      string(name),
      arguments(args, blueprint),
      ": ",
      render(field_type, blueprint)
    ])
    |> deprecated(is_deprecated, deprecation_reason)
    |> description(description)
  end

  def render(%Schema.FieldDefinition{} = field, blueprint) do
    adapter = blueprint.adapter || Absinthe.Adapter.LanguageConventions

    concat([
      string(adapter.to_external_name(field.name, :field)),
      arguments(field.arguments, blueprint),
      ": ",
      render(field.type, blueprint)
    ])
    |> deprecated(!!field.deprecation, field.deprecation)
    |> description(field.description)
  end

  # OBJECT
  def render(
        %{
          "kind" => "OBJECT",
          "name" => name,
          "description" => description,
          "fields" => fields,
          "interfaces" => interfaces
        },
        blueprint
      ) do
    block(
      "type",
      concat([
        string(name),
        implements(interfaces, blueprint)
      ]),
      Enum.map(fields, &render(&1, blueprint))
    )
    |> description(description)
  end

  def render(%Schema.ObjectTypeDefinition{} = object_type, blueprint) do
    block(
      "type",
      concat([
        string(object_type.name),
        implements(object_type.interfaces, blueprint)
      ]),
      Enum.map(object_type.fields, &render(&1, blueprint))
    )
    |> description(object_type.description)
  end

  # INPUT_OBJECT
  def render(
        %{
          "kind" => "INPUT_OBJECT",
          "name" => name,
          "description" => description,
          "inputFields" => input_fields
        },
        blueprint
      ) do
    block(
      "input",
      string(name),
      Enum.map(input_fields, &render(&1, blueprint))
    )
    |> description(description)
  end

  def render(
        %Schema.InputObjectTypeDefinition{} = input_object_type,
        blueprint
      ) do
    block(
      "input",
      string(input_object_type.name),
      Enum.map(input_object_type.fields, &render(&1, blueprint))
    )
    |> description(input_object_type.description)
  end

  # UNION
  def render(
        %{
          "kind" => "UNION",
          "name" => name,
          "description" => description,
          "possibleTypes" => possible_types
        },
        _blueprint
      ) do
    possible_type_docs = Enum.map(possible_types, & &1["name"])

    concat([
      "union ",
      string(name),
      " = ",
      join(possible_type_docs, " | ")
    ])
    |> description(description)
  end

  def render(
        %Schema.UnionTypeDefinition{} = union_type,
        _blueprint
      ) do
    possible_type_docs = Enum.map(union_type.types, & &1.name)

    concat([
      "union ",
      string(union_type.name),
      " = ",
      join(possible_type_docs, " | ")
    ])
    |> description(union_type.description)
  end

  # INTERFACE

  def render(
        %{
          "kind" => "INTERFACE",
          "name" => name,
          "description" => description,
          "fields" => fields
        },
        blueprint
      ) do
    block(
      "interface",
      string(name),
      Enum.map(fields, &render(&1, blueprint))
    )
    |> description(description)
  end

  def render(
        %Absinthe.Blueprint.Schema.InterfaceTypeDefinition{} = interace_type,
        blueprint
      ) do
    block(
      "interface",
      string(interace_type.name),
      Enum.map(interace_type.fields, &render(&1, blueprint))
    )
    |> description(interace_type.description)
  end

  # ENUM

  def render(
        %{
          "kind" => "ENUM",
          "name" => name,
          "description" => description,
          "enumValues" => values
        },
        _blueprint
      ) do
    block(
      "enum",
      string(name),
      Enum.map(values, &string(&1["name"]))
    )
    |> description(description)
  end

  def render(
        %Absinthe.Blueprint.Schema.EnumTypeDefinition{} = enum_type,
        _blueprint
      ) do
    block(
      "enum",
      string(enum_type.name),
      Enum.map(enum_type.values, &string(&1.name))
    )
    |> description(enum_type.description)
  end

  # SCALAR
  def render(
        %{
          "kind" => "SCALAR",
          "name" => name,
          "description" => description
        },
        _blueprint
      ) do
    space("scalar", string(name))
    |> description(description)
  end

  def render(
        %Absinthe.Blueprint.Schema.ScalarTypeDefinition{} = scalar_type,
        _blueprint
      ) do
    space("scalar", string(scalar_type.name))
    |> description(scalar_type.description)
  end

  def render(
        %{
          "name" => name,
          "locations" => _
        },
        _blueprint
      )
      when name in @builtin_directives do
    empty()
  end

  # DIRECTIVE
  def render(
        %{
          "name" => name,
          "description" => description,
          "args" => args,
          "locations" => locations
        },
        blueprint
      ) do
    concat([
      "directive ",
      concat("@", string(name)),
      arguments(args, blueprint),
      " on ",
      join(locations, " | ")
    ])
    |> description(description)
  end

  def render(%Schema.DirectiveDefinition{} = directive, blueprint) do
    locations = directive.locations |> Enum.map(&String.upcase(to_string(&1)))

    concat([
      "directive ",
      concat("@", string(directive.name)),
      arguments(directive.arguments, blueprint),
      " on ",
      join(locations, " | ")
    ])
    |> description(directive.description)
  end

  def render(%{"ofType" => nil, "kind" => "SCALAR", "name" => name}, _blueprint) do
    string(name)
  end

  def render(%{"ofType" => nil, "name" => name}, _blueprint) do
    string(name)
  end

  def render(%Absinthe.Blueprint.TypeReference.Name{name: name}, _blueprint) do
    string(name)
  end

  def render(%{"ofType" => type, "kind" => "LIST"}, blueprint) do
    concat(["[", render(type, blueprint), "]"])
  end

  def render(%Absinthe.Blueprint.TypeReference.List{of_type: of_type}, blueprint) do
    concat(["[", render(of_type, blueprint), "]"])
  end

  def render(%{"ofType" => type, "kind" => "NON_NULL"}, blueprint) do
    concat([render(type, blueprint), "!"])
  end

  def render(%Absinthe.Blueprint.TypeReference.NonNull{of_type: of_type}, blueprint) do
    concat([render(of_type, blueprint), "!"])
  end

  def render(%{"name" => name}, _blueprint) do
    string(name)
  end

  def render(:integer, _), do: "Int"

  def render(type, _blueprint) when is_atom(type) and type in @builtin_scalar_identifiers do
    type |> to_string |> String.capitalize()
  end

  def render(identifier, blueprint) when is_atom(identifier) do
    case Absinthe.Blueprint.Schema.lookup_type(blueprint, identifier) do
      %{name: name} -> name
    end
  end

  def render(%{__struct__: struct} = something, _blueprint) do
    IO.inspect(something)
    raise inspect(struct)
  end

  def arguments([], _blueprint) do
    empty()
  end

  def arguments(args, blueprint) do
    arg_docs = Enum.map(args, &render(&1, blueprint))

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

  def implements([], _blueprint) do
    empty()
  end

  def implements(interfaces, blueprint) do
    interface_names =
      Enum.map(interfaces, fn
        %{"name" => name} ->
          name

        identifier when is_atom(identifier) ->
          case Absinthe.Blueprint.Schema.lookup_type(blueprint, identifier) do
            %{name: name} -> name
          end
      end)

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
