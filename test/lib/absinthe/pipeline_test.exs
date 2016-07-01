defmodule Absinthe.PipelineTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline}

  describe '.run' do

    @query """
    { foo { bar } }
    """

    it 'can create a blueprint' do
      assert {:ok, %Blueprint{}} = Pipeline.run(@query, Pipeline.locked([Phase.Parse, Phase.Blueprint]))
    end

  end

end
