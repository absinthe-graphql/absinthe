defmodule Absinthe.Phase.Operation.VariablesTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline}

  @pre_pipeline [Phase.Parse, Phase.Blueprint]

  describe 'given matching variables' do

    @query """
    query Foo($id: ID!) {
      foo(id: $id) {
        bar
      }
    }
    """

    @tag :pending
    it "sets the variable definitions appropriately" do
      # TODO: Actually test that variable values have been set
      assert %Blueprint{} = blueprint(@query)
    end

  end

  defp blueprint(query) do
    with {:ok, blueprint} <- Pipeline.run(query, @pre_pipeline) do
      blueprint
    end
  end

end
