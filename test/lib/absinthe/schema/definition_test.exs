defmodule Absinthe.Schema.DefinitionTest do
  use ExSpec, async: true

  defmodule Schema do
    import Absinthe.Schema.Definition

    object :person, [
      fields: [
        name: [type: :string]
      ]
    ]

  end


  describe "object" do

    it "defines an object" do
      obj = Schema.__absinthe_type__(:person)
      IO.inspect(obj)
      assert obj.name == "Person"
    end

  end

end
