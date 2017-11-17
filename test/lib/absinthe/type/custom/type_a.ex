defmodule Absinthe.Type.Custom.TypeA do
  use Absinthe.Schema.Notation
  
  object :type_a do
    field :a_id, non_null(:id)
    field :a_string, non_null(:string)
  end
end