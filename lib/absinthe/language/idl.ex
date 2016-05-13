defmodule Absinthe.Language.IDL do
  @moduledoc false

  alias Absinthe.{Schema, Language, Type}

  @spec to_idl_ast(atom) :: Language.Document.t
  def to_idl_ast(schema) do
    %Language.Document{
      definitions: Enum.map(Enum.reject(Absinthe.Schema.types(schema), &Absinthe.Type.built_in?/1), &to_idl_ast(&1, schema))
    }
  end

  @spec to_idl_ast(Absinthe.Type.t, Absinthe.Schema.t) :: Language.t
  def to_idl_ast(%Type.Object{} = node, schema) do
    %Language.ObjectDefinition{
      name: node.name,
      fields: Enum.map(Map.values(node.fields), &to_idl_ast(node, &1, schema)),
      interfaces: Enum.map(node.interfaces, &to_idl_named_type_ast(&1, schema))
    }
  end
  def to_idl_ast(%Type.InputObject{} = node, schema) do
    %Language.InputObjectDefinition{
      name: node.name,
      fields: Enum.map(Map.values(node.fields), &to_idl_ast(node, &1, schema))
    }
  end
  def to_idl_ast(%Type.Interface{} = node, schema) do
    %Language.InterfaceDefinition{
      name: node.name,
      fields: Enum.map(Map.values(node.fields), &to_idl_ast(node, &1, schema))
    }
  end
  def to_idl_ast(%Type.Enum{} = node, _schema) do
    %Language.EnumTypeDefinition{
      name: node.name,
      values: Enum.map(Map.values(node.values), &Map.get(&1, :name))
    }
  end
  def to_idl_ast(%Type.Union{} = node, schema) do
    %Language.UnionTypeDefinition{
      name: node.name,
      types: Enum.map(node.types, &to_idl_named_type_ast(&1, schema))
    }
  end
  def to_idl_ast(%Type.Scalar{} = node, _schema) do
    %Language.ScalarTypeDefinition{
      name: node.name
    }
  end
  def to_idl_ast(%Type.Argument{} = node, schema) do
    %Language.InputValueDefinition{
      name: node.name,
      type: to_idl_ast(node.type, schema)
    }
  end
  def to_idl_ast(%Type.List{of_type: type}, schema) do
    %Language.ListType{
      type: to_idl_ast(type, schema)
    }
  end
  def to_idl_ast(%Type.NonNull{of_type: type}, schema) do
    %Language.NonNullType{
      type: to_idl_ast(type, schema)
    }
  end
  def to_idl_ast(node, schema) when is_atom(node) do
    %Language.NamedType{name: schema.__absinthe_type__(node).name}
  end
  def to_idl_ast(%Type.Directive{} = node, schema) do
    %Language.DirectiveDefinition{
      name: node.name,
      arguments: Enum.map(Map.values(node.args), &to_idl_ast(&1, schema)),
      locations: Enum.map(node.locations, fn loc ->
        loc |> Atom.to_string |> String.upcase
      end)
    }
  end


  @spec to_idl_ast(Type.t, Type.t, Schema.t) :: Language.t
  defp to_idl_ast(%Type.InputObject{}, %Type.Field{} = node, schema) do
    %Language.InputValueDefinition{
      name: node.name,
      default_value: to_idl_default_value_ast(Schema.lookup_type(schema, node.type, unwrap: false), node.default_value, schema),
      type: to_idl_ast(node.type, schema)
    }
  end
  defp to_idl_ast(%{__struct__: str}, %Type.Field{} = node, schema) when str in [Type.Object, Type.Interface] do
    %Language.FieldDefinition{
      name: node.name,
      arguments: Enum.map(Map.values(node.args), &to_idl_ast(&1, schema)),
      type: to_idl_ast(node.type, schema)
    }
  end

  defp to_idl_named_type_ast(identifier, schema) do
    name = schema.__absinthe_type__(identifier).name
    %Language.NamedType{name: name}
  end

  defp to_idl_default_value_ast(_, nil, _), do: nil
  defp to_idl_default_value_ast(%Type.Scalar{name: "Boolean"}, value, _schema) do
    %Language.BooleanValue{value: value}
  end
  defp to_idl_default_value_ast(%Type.Scalar{name: "Int"}, value, _schema) do
    %Language.IntValue{value: value}
  end
  defp to_idl_default_value_ast(%Type.Scalar{name: "String"}, value, _schema) do
    %Language.StringValue{value: value}
  end
  defp to_idl_default_value_ast(%Type.Scalar{name: "ID"}, value, _schema) do
    %Language.StringValue{value: value}
  end
  defp to_idl_default_value_ast(%Type.Scalar{name: "Float"}, value, _schema) do
    %Language.FloatValue{value: value}
  end

  defp to_idl_default_value_ast(%Type.List{of_type: type}, value, schema) do
    internal_type = Schema.lookup_type(schema, type, unwrap: false)
    %Language.ListValue{
      values: Enum.map(value, &to_idl_default_value_ast(internal_type, &1, schema))
    }
  end

  @spec to_idl_iodata(Language.t, Schema.t) :: iodata
  def to_idl_iodata(%Language.Document{} = doc, schema) do
    [
      "schema {\n",
      Enum.map(~w(query mutation subscription)a, &to_idl_root_iodata(&1, schema)),
      "}\n",
      Enum.map(doc.definitions, &(to_idl_iodata(&1, schema)))
    ]
  end
  def to_idl_iodata(%Language.ObjectDefinition{} = node, schema) do
    [
      "type ",
      node.name,
      implements_iodata(node.interfaces),
      " {\n",
      indented(2, node.fields, schema),
      "}\n"
    ]
  end
  def to_idl_iodata(%Language.InterfaceDefinition{} = node, schema) do
    [
      "interface ",
      node.name,
      " {\n",
      indented(2, node.fields, schema),
      "}\n"
    ]
  end
  def to_idl_iodata(%Language.InputObjectDefinition{} = node, schema) do
    [
      "input ",
      node.name,
      " {\n",
      indented(2, node.fields, schema),
      "}\n"
    ]
  end
  def to_idl_iodata(%Language.FieldDefinition{} = node, schema) do
    [
      node.name,
      arguments_idl_iodata(node.arguments, schema),
      ": ",
      to_idl_iodata(node.type, schema),
    ]
  end
  def to_idl_iodata(%Language.InputValueDefinition{} = node, schema) do
    [
      node.name,
      ": ",
      to_idl_iodata(node.type, schema),
      default_idl_iodata(node.default_value),
    ]
  end
  def to_idl_iodata(%Language.EnumTypeDefinition{} = node, schema) do
    [
      "enum ",
      node.name,
      " {\n",
      indented(2, node.values, schema),
      "}\n"
    ]
  end
  def to_idl_iodata(%Language.UnionTypeDefinition{} = node, _schema) do
    [
      "union ",
      node.name,
      " = ",
      Enum.map(node.types, &Map.get(&1, :name))
      |> Enum.join(" | ")
    ]
  end
  def to_idl_iodata(%Language.ScalarTypeDefinition{} = node, _schema) do
    [
      "scalar ",
      node.name,
      "\n"
    ]
  end
  def to_idl_iodata(%Language.NamedType{} = node, _schema) do
    node.name
  end
  def to_idl_iodata(%Language.NonNullType{} = node, schema) do
    [
      to_idl_iodata(node.type, schema),
      "!"
    ]
  end
  def to_idl_iodata(%Language.ListType{} = node, schema) do
    [
      "[",
      to_idl_iodata(node.type, schema),
      "]"
    ]
  end
  def to_idl_iodata(%Language.DirectiveDefinition{} = node, schema) do
    [
      "directive @",
      node,
      arguments_idl_iodata(node.arguments, schema),
      " on ",
      Enum.intersperse(node.locations, ' '),
      "\n"
    ]
  end

  def to_idl_iodata(value, _schema) when is_binary(value) do
    value
  end

  defp to_idl_root_iodata(name, schema) do
    case Schema.lookup_type(schema, name) do
      nil ->
        ""
      object ->
        "  #{name}: #{object.name}\n"
    end
  end

  defp implements_iodata([]) do
    []
  end
  defp implements_iodata(interfaces) do
    [
      " implements ",
      interfaces
      |> Enum.map(&Map.get(&1, :name))
      |> Enum.join(", ")
    ]
  end

  defp default_idl_iodata(nil) do
    ""
  end
  defp default_idl_iodata(node) do
    [
      " = ",
      do_default_idl_iodata(node)
    ]
  end

  defp do_default_idl_iodata(%Language.StringValue{} = node) do
    node.value
    |> inspect
  end
  defp do_default_idl_iodata(%Language.IntValue{} = node) do
    node.value
    |> Integer.to_string
  end
  defp do_default_idl_iodata(%Language.FloatValue{} = node) do
    node.value
    |> Float.to_string
  end
  defp do_default_idl_iodata(%Language.BooleanValue{} = node) do
    node.value
    |> to_string
  end
  defp do_default_idl_iodata(%Language.ListValue{} = node) do
    [
      "[",
      Enum.map(node.values, &do_default_idl_iodata/1),
      "]"
    ]
  end
  defp do_default_idl_iodata(%Language.ObjectValue{} = node) do
    [
      "{",
      Enum.map(node.fields, &do_default_idl_iodata/1),
      "}"
    ]
  end
  defp do_default_idl_iodata(%Language.ObjectField{} = node) do
    [
      node.name,
      ": ",
      do_default_idl_iodata(node.value)
    ]
  end

  defp arguments_idl_iodata([], _schema) do
    []
  end
  defp arguments_idl_iodata(arguments, schema) do
    [
      "(",
      Enum.intersperse(Enum.map(arguments, &to_idl_iodata(&1, schema)), ", "),
      ")"
    ]
  end

  defp indented(amount, collection, schema) do
    indent = 1..amount |> Enum.map(fn _ -> " " end)
    Enum.map(collection, fn
      member ->
        [indent, to_idl_iodata(member, schema), "\n"]
    end)
  end

end
