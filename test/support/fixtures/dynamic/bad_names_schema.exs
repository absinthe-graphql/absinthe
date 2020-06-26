defmodule Absinthe.TestSupport.Schema.BadNamesSchema do
  use Absinthe.Schema

  object :car, name: "bad object name" do
    # ...
  end

  input_object :contact_input, name: "bad input name" do
    field :email, non_null(:string)
  end

  directive :mydirective, name: "bad directive name" do
    on :field
  end

  scalar :time, description: "ISOz time", name: "bad?scalar#name" do
    parse fn x -> x end
    serialize fn x -> x end
  end

  query do
    field :foo, :string, name: "bad field name"

    field :bar, :car do
      arg :foo, :string, name: "bad arg name"
    end
  end
end
