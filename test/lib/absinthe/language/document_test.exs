defmodule Absinthe.Languguage.DocumentTest do
  use Absinthe.Case, async: true

  alias Absinthe.Language.Document
  alias Absinthe.Language.OperationDefinition

  @input """
  query MyQuery1 {
    thing(id: "1") {
      name
    }
  }
  query MyQuery2 {
    thing(id: "1") {
      name
    }
  }
  mutation MyMutation {
    thing(id: "1") {
      name
    }
  }

  """

  describe "get_operation/2" do

    describe "given an existing operation name" do

      it "returns the operation definition" do
        doc = Absinthe.parse!(@input)
        result = Document.get_operation(doc, "MyQuery2")
        assert %OperationDefinition{name: "MyQuery2", operation: :query} = result
      end

    end

    describe "given a non-existing operation name" do
      doc = Absinthe.parse!(@input)
      result = Document.get_operation(doc, "DoesNotExist")
      assert nil == result
    end

  end

end
