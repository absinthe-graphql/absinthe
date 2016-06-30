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

  @ast_modules_to_blueprint_modules %{
    Language.BooleanValue => Input.Boolean,
    Language.EnumValue => Input.Enum,
    Language.FloatValue => Input.Float,
    Language.IntValue => Input.Integer,
    Language.ListValue => Input.List,
    Language.ObjectValue => Input.Object,
    Language.StringValue => Input.String,
    Language.Variable => Input.Variable
  }
  @supported_ast_node_modules Map.keys(@ast_modules_to_blueprint_modules)

  @spec from_ast(Language.input_t, Language.Document.t) :: t
  def from_ast(%{__struct__: mod} = node, doc) when mod in @supported_ast_node_modules do
    @ast_modules_to_blueprint_modules[mod].from_ast(node, doc)
  end

end
