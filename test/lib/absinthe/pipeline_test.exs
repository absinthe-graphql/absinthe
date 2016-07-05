defmodule Absinthe.PipelineTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Pipeline, Phase}

  describe '.run an operation' do

    @query """
    { foo { bar } }
    """

    it 'can create a blueprint' do
      assert {:ok, %Blueprint{}} = Pipeline.run(@query, Pipeline.for_query)
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

  defmodule Phase1 do
    def run(input) do
      {:ok, String.reverse(input)}
    end
  end

  defmodule Phase2 do
    def run(input, options) do
      result = (1..options[:times])
      |> Enum.map(fn _ -> input end)
      |> Enum.join(".")
      {:ok, result}
    end
  end

  defmodule Phase3 do
    def run(input, %{reverse: true}) do
      {:ok, String.reverse(input)}
    end
    def run(input, %{reverse: false}) do
      {:ok, input}
    end
  end

  describe ".run with options" do
    it "should work" do
      assert {:ok, "oof.oof.oof"} == Pipeline.run("foo", [Phase1, {Phase2, times: 3}, {Phase3, %{reverse: false}}])
      assert {:ok, "foo.foo.foo"} == Pipeline.run("foo", [Phase1, {Phase2, times: 3}, {Phase3, %{reverse: true}}])
    end
  end

  defmodule BadPhase do
    def run(input) do
      input
    end
  end

  describe ".run with a bad phase result" do
    it "should return a nice error object" do
      assert {:error, %Phase.Error{phase: BadPhase, message: "Phase did not return an {:ok, any} | {:error, Absinthe.Phase.Error.t} | {:error, String.t}"}} ==  Pipeline.run("foo", [BadPhase])
    end
  end

end
