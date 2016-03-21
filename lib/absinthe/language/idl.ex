defmodule Absinthe.Language.IDL do

  alias Absinthe.Schema
  alias Absinthe.Language
  alias Absinthe.Type

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
      fields: Enum.map(Map.values(node.fields), &to_idl_ast(node, &1, schema))
    }
  end
  def to_idl_ast(%Type.InputObject{} = node, schema) do
    %Language.InputObjectDefinition{
      name: node.name,
      fields: Enum.map(Map.values(node.fields), &to_idl_ast(node, &1, schema))
    }
  end
  def to_idl_ast(%Type.Argument{} = node, schema) do
    %Language.InputValueDefinition{
      name: node.name,
      type: to_idl_ast(node.type, schema)
    }
  end
  def to_idl_ast(%Type.List{of_type: type} = node, schema) do
    %Language.ListType{
      type: to_idl_ast(type, schema)
    }
  end
  def to_idl_ast(%Type.NonNull{of_type: type} = node, schema) do
    %Language.NonNullType{
      type: to_idl_ast(type, schema)
    }
  end
  def to_idl_ast(node, schema) when is_atom(node) do
    %Language.NamedType{name: schema.__absinthe_type__(node).name}
  end

  @spec to_idl_ast(Type.t, Type.t, Schema.t) :: Language.t
  defp to_idl_ast(%Type.InputObject{}, %Type.Field{} = node, schema) do
    %Language.InputValueDefinition{
      name: node.name,
      default_value: node.default_value,
      type: to_idl_ast(node.type, schema)
    }
  end
  defp to_idl_ast(%Type.Object{}, %Type.Field{} = node, schema) do
    %Language.FieldDefinition{
      name: node.name,
      arguments: Enum.map(Map.values(node.args), &to_idl_ast(&1, schema)),
      type: to_idl_ast(node.type, schema)
    }
  end

  @spec to_idl_iodata(Language.t) :: iodata
  def to_idl_iodata(%Language.Document{} = doc) do
    doc.definitions
    |> Enum.map(&to_idl_iodata/1)
  end
  def to_idl_iodata(%Language.ObjectDefinition{} = node) do
    [
      "type ",
      node.name,
      " {\n",
      indented(2, node.fields),
      "}\n"
    ]
  end
  def to_idl_iodata(%Language.InputObjectDefinition{} = node) do
    [
      "input ",
      node.name,
      " {\n",
      indented(2, node.fields),
      "}\n"
    ]
  end
  def to_idl_iodata(%Language.FieldDefinition{} = node) do
    [
      node.name,
      arguments_idl_iodata(node.arguments),
      ": ",
      to_idl_iodata(node.type),
      "\n"
    ]
  end
  def to_idl_iodata(%Language.InputValueDefinition{} = node) do
    [
      node.name,
      ": ",
      to_idl_iodata(node.type),
      default_idl_iodata(node.default_value),
      "\n"
    ]
  end
  def to_idl_iodata(%Language.NamedType{} = node) do
    node.name
  end
  def to_idl_iodata(%Language.NonNullType{} = node) do
    [
      to_idl_iodata(node.type),
      "!"
    ]
  end
  def to_idl_iodata(%Language.ListType{} = node) do
    [
      "[",
      to_idl_iodata(node.type),
      "]"
    ]
  end


  defp default_idl_iodata(nil), do: ""
  defp default_idl_iodata(value) when is_binary(value), do: ~s( = "#{value}")
  defp default_idl_iodata(value), do: " = #{value}"

  defp arguments_idl_iodata([]) do
    ""
  end
  defp arguments_idl_iodata(arguments) do
    [
      "(",
      Enum.intersperse(Enum.map(arguments, &to_idl_iodata/1), ", "),
      ")"
    ]
  end

  defp indented(amount, collection) do
    indent = 1..amount |> Enum.map(fn _ -> " " end)
    Enum.map(collection, fn
      member ->
        [indent, to_idl_iodata(member)]
    end)
  end

end
