defmodule Absinthe.Blueprint.Input do
  alias Absinthe.{Blueprint, Language}
  alias __MODULE__

  @type leaf :: Input.Integer.t
    | Input.Float.t
    | Input.Enum.t
    | Input.String.t
    | Input.Variable.t
    | Input.Boolean.t

  @type collection :: Blueprint.Input.List.t | Input.Object.t

  @type t :: leaf | collection

  @mapping %{
    Language.BooleanValue => Input.Boolean,
    Language.EnumValue => Input.Enum,
    Language.FloatValue => Input.Float,
    Language.IntValue => Input.Integer,
    Language.ListValue => Input.List,
    Language.ObjectValue => Input.Object,
    Language.StringValue => Input.String,
  }

  def from_ast(%Language.ObjectValue{} = node, doc) do
    %Input.Object{
      fields: Enum.map(node.fields, &Input.Field.from_ast(&1, doc)),
      ast_node: node
    }
  end
  def from_ast(%{__struct__: ast_node_struct} = node, _doc) do
    struct(
      @mapping[ast_node_struct],
      [
        value: node.value,
        ast_node: node
      ]
    )
  end

end
