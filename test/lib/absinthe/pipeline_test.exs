defmodule Absinthe.PipelineTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Pipeline, Phase}

  defmodule Schema do
    use Absinthe.Schema
  end

  describe '.run an operation' do

    @query """
    { foo { bar } }
    """

    it "can create a blueprint" do
      pipeline = Pipeline.for_document(Schema)
      |> Pipeline.upto(Phase.Blueprint)
      assert {:ok, %Blueprint{}, [Phase.Blueprint, Phase.Parse]} = Pipeline.run(@query, pipeline)
    end

  end

  describe '.run an idl' do

    @query """
    type Person {
      name: String!
    }
    """

    it 'can create a blueprint without a prototype schema' do
      assert {:ok, %Blueprint{}, _} = Pipeline.run(@query, Pipeline.for_schema(nil))
    end

    it 'can create a blueprint with a prototype schema' do
      assert {:ok, %Blueprint{}, _} = Pipeline.run(@query, Pipeline.for_schema(Schema))
    end

  end

  defmodule Phase1 do
    use Phase
    def run(input) do
      {:ok, String.reverse(input)}
    end
  end

  defmodule Phase2 do
    use Phase
    def run(input, %{times: times}) do
      result = (1..times)
      |> Enum.map(fn _ -> input end)
      |> Enum.join(".")
      {:ok, result}
    end
  end

  defmodule Phase3 do
    use Phase
    def run(input, options) do
      do_run(input, Enum.into(options, %{}))
    end

    defp do_run(input, %{reverse: true}) do
      {:ok, String.reverse(input)}
    end
    defp do_run(input, %{reverse: false}) do
      {:ok, input}
    end
  end

  describe ".run with options" do
    it "should work" do
      assert {:ok, "oof.oof.oof", [Phase3, Phase2, Phase1]} == Pipeline.run("foo", [Phase1, {Phase2, %{times: 3}}, {Phase3, %{reverse: false}}])
      assert {:ok, "foo.foo.foo", [Phase3, Phase2, Phase1]} == Pipeline.run("foo", [Phase1, {Phase2, %{times: 3}}, {Phase3, %{reverse: true}}])
    end
  end

  defmodule BadPhase do
    use Phase
    def run(input) do
      input
    end
  end

  describe ".run with a bad phase result" do
    it "should return a nice error object" do
      assert {:error, "Last phase did not return a valid result tuple.", [BadPhase]} == Pipeline.run("foo", [BadPhase])
    end
  end

  @pipeline [A, B, C, D, {E, []}, F]

  describe ".before" do

    it "raises an exception if one can't be found" do
      assert_raise RuntimeError, fn -> Pipeline.before([], Anything) end
    end

    it "returns the phases before" do
      assert [] == Pipeline.before(@pipeline, A)
      assert [A, B, C] == Pipeline.before(@pipeline, D)
      assert [A, B, C, D] == Pipeline.before(@pipeline, E)
    end

  end

  describe ".insert_before" do

    it "raises an exception if one can't be found" do
      assert_raise RuntimeError, fn -> Pipeline.insert_before([], Anything, X) end
    end

    it "inserts the phase before" do
      assert [X, A, B, C, D, {E, []}, F] == Pipeline.insert_before(@pipeline, A, X)
      assert [A, B, C, D, X, {E, []}, F] == Pipeline.insert_before(@pipeline, E, X)
    end

  end

  describe ".upto" do

    it "raises an exception if one can't be found" do
      assert_raise RuntimeError, fn -> Pipeline.upto([], Anything) end
    end

    it "returns the phases upto the match" do
      assert [A, B, C] == Pipeline.upto(@pipeline, C)
      assert [A, B, C, D, {E, []}] == Pipeline.upto(@pipeline, E)
    end

  end

end
