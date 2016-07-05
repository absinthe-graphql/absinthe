defmodule Absinthe.Blueprint.Input do
  alias Absinthe.Blueprint
  alias __MODULE__

  @type leaf ::
      Input.Integer.t
    | Input.Float.t
    | Input.Enum.t
    | Input.String.t
    | Input.Variable.t
    | Input.Boolean.t

  @type collection ::
      Blueprint.Input.List.t
    | Input.Object.t

  @type t :: leaf | collection

  @parse_types [
    Input.Boolean,
    Input.Enum,
    Input.Field,
    Input.Float,
    Input.Integer,
    Input.List,
    Input.Object,
    Input.String,
  ]

  @spec parse(any) :: nil | t
  def parse(%struct{} = value) when struct in @parse_types do
    value
  end
  def parse(value) when is_integer(value) do
    %Input.Integer{value: value}
  end
  def parse(value) when is_float(value) do
    %Input.Float{value: value}
  end
  # Note: The value may actually be an Enum value and may
  # need to be manually converted, based on the schema.
  def parse(value) when is_binary(value) do
    %Input.String{value: value}
  end
  def parse(value) when is_boolean(value) do
    %Input.Boolean{value: value}
  end
  def parse(value) when is_list(value) do
    %Input.List{
      values: Enum.map(value, &parse/1)
    }
  end
  def parse(value) when is_map(value) do
    %Input.Object{
      fields: Enum.map(value, fn
        {name, field_value} ->
          %Input.Field{
            name: name,
            value: parse(field_value),
          }
      end)
    }
  end
  def parse(nil) do
    nil
  end


end
