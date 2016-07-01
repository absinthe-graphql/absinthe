defmodule Absinthe.PipelineTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Pipeline}

  describe '.run an operation' do

    @query """
    { foo { bar } }
    """

    it 'can create a blueprint' do
      assert {:ok, %Blueprint{}} = Pipeline.run(@query, Pipeline.for_operation)
    end

  end

  describe '.run an idl' do

    @query """
    type Person {
      name: String!
    }
    """

    it 'can create a blueprint' do
      assert {:ok, %Blueprint{}} = Pipeline.run(@query, Pipeline.for_schema)
    end

  end

end
