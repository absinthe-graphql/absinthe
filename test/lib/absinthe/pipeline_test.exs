defmodule Absinthe.PipelineTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Pipeline, Phase}

  describe '.run an operation' do

    @query """
    { foo { bar } }
    """

    it 'can create a blueprint' do
      assert {:ok, %Blueprint{}} = Pipeline.run(@query, Pipeline.for_document)
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
    use Phase
    def run(input, _) do
      {:ok, String.reverse(input)}
    end
  end

  defmodule Phase2 do
    use Phase
    def run(input, options) do
      result = (1..options[:times])
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
      assert {:ok, "oof.oof.oof"} == Pipeline.run("foo", [Phase1, {Phase2, times: 3}, {Phase3, %{reverse: false}}])
      assert {:ok, "foo.foo.foo"} == Pipeline.run("foo", [Phase1, {Phase2, times: 3}, {Phase3, %{reverse: true}}])
    end
  end

  defmodule BadPhase do
    use Phase
    def run(input, _) do
      input
    end
  end

  describe ".run with a bad phase result" do
    it "should return a nice error object" do
      assert {:error, %Phase.Error{phase: BadPhase, message: "Phase did not return an {:ok, any} | {:error, Absinthe.Phase.Error.t} | {:error, String.t}"}} ==  Pipeline.run("foo", [BadPhase])
    end
  end

  defmodule PhaseDeps.BadPrePhase do
    use Phase
    def run(input, _) do
      {:ok, input}
    end
  end

  defmodule PhaseDeps.GoodPrePhase do
    use Phase
    def run(input, _) do
      {:ok, %{input | flag: true}}
    end
  end

  defmodule PhaseDeps.Check do
    use Phase
    def run(input, _) do
      {:ok, %{input | checked: true}}
    end

    def check_input(%{flag: true}) do
      :ok
    end
    def check_input(_) do
      {:error, "input.flag must be true"}
    end
  end

  describe ".run with a phase that checks input" do
    @input %{flag: false, checked: false}

    it "when an earlier phase sets input appropriately" do
      assert {:ok, %{flag: true, checked: true}} == Pipeline.run(@input, [PhaseDeps.GoodPrePhase, PhaseDeps.Check])
    end

    it "when an earlier phase does not set input appropriately" do
      assert {:error, %Phase.Error{phase: PhaseDeps.Check, message: "input.flag must be true"}} == Pipeline.run(@input, [PhaseDeps.BadPrePhase, PhaseDeps.Check])
    end
  end

end
