defmodule Absinthe.PipelineTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Pipeline, Phase}

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end
  end

  describe ".run an operation" do
    @query """
    { foo { bar } }
    """

    test "can create a blueprint" do
      pipeline =
        Pipeline.for_document(Schema)
        |> Pipeline.upto(Phase.Blueprint)

      assert {:ok, %Blueprint{}, [Phase.Blueprint, Phase.Parse, Phase.Telemetry, Phase.Init]} =
               Pipeline.run(@query, pipeline)
    end
  end

  describe ".run handles pipelines that exclude Execution and Subscription phases" do
    defmodule ValidationOnlySchema do
      use Absinthe.Schema

      query do
        field :foo, :Stuff do
          resolve fn _, _, _ -> nil end
        end
      end

      object :Stuff do
        field :bar, :string
      end
    end

    @good_query """
    { foo { bar } }
    """

    @bad_query """
    { noFoo { bar } }
    """
    test "well-formed query" do
      {:ok, %{execution: %{validation_errors: validation_errors}}, _} =
        validation_only_query(@good_query)

      assert length(validation_errors) == 0
    end

    test "ill-formed query" do
      {:ok, %{execution: %{validation_errors: validation_errors}}, _} =
        validation_only_query(@bad_query)

      refute length(validation_errors) == 0
    end

    defp validation_only_query(query) do
      pipeline =
        Pipeline.for_document(ValidationOnlySchema)
        |> Pipeline.without(Phase.Subscription.SubscribeSelf)
        |> Pipeline.without(Phase.Document.Execution.Resolution)

      Pipeline.run(query, pipeline)
    end
  end

  describe "default pipeline accepts possible inputs" do
    @query """
    { foo { bar } }
    """

    test "query string" do
      pipeline =
        Pipeline.for_document(Schema)
        |> Pipeline.upto(Phase.Blueprint)

      pipeline_input = @query

      assert {:ok, %Blueprint{operations: [%{selections: [%{name: "foo"}]}]}, _phases} =
               Pipeline.run(pipeline_input, pipeline)
    end

    test "language source" do
      pipeline =
        Pipeline.for_document(Schema)
        |> Pipeline.upto(Phase.Blueprint)

      pipeline_input = %Absinthe.Language.Source{body: @query}

      assert {:ok, %Blueprint{operations: [%{selections: [%{name: "foo"}]}]}, _phases} =
               Pipeline.run(pipeline_input, pipeline)
    end

    test "blueprint" do
      pipeline =
        Pipeline.for_document(Schema)
        |> Pipeline.upto(Phase.Blueprint)

      pipeline_input = %Blueprint{input: @query}

      assert {:ok, %Blueprint{operations: [%{selections: [%{name: "foo"}]}]}, _phases} =
               Pipeline.run(pipeline_input, pipeline)
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
      do_run(input, Map.new(options))
    end

    def do_run(input, %{times: times}) do
      result =
        1..times
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
    test "should work" do
      assert {:ok, "oof.oof.oof", [Phase3, Phase2, Phase1]} ==
               Pipeline.run("foo", [Phase1, {Phase2, times: 3}, {Phase3, reverse: false}])

      assert {:ok, "foo.foo.foo", [Phase3, Phase2, Phase1]} ==
               Pipeline.run("foo", [Phase1, {Phase2, times: 3}, {Phase3, reverse: true}])
    end
  end

  defmodule BadPhase do
    use Phase

    def run(input, _) do
      input
    end
  end

  describe ".run with a bad phase result" do
    test "should return a nice error object" do
      assert {:error, "Last phase did not return a valid result tuple.", [BadPhase]} ==
               Pipeline.run("foo", [BadPhase])
    end
  end

  @pipeline [A, B, C, D, {E, [name: "e"]}, F]

  describe ".before" do
    test "raises an exception if one can't be found" do
      assert_raise RuntimeError, fn -> Pipeline.before([], Anything) end
    end

    test "returns the phases before" do
      assert [] == Pipeline.before(@pipeline, A)
      assert [A, B, C] == Pipeline.before(@pipeline, D)
      assert [A, B, C, D] == Pipeline.before(@pipeline, E)
    end
  end

  describe ".insert_before" do
    test "raises an exception if one can't be found" do
      assert_raise RuntimeError, fn -> Pipeline.insert_before([], Anything, X) end
    end

    test "inserts the phase before" do
      assert [X, A, B, C, D, {E, [name: "e"]}, F] == Pipeline.insert_before(@pipeline, A, X)
      assert [A, B, C, D, X, {E, [name: "e"]}, F] == Pipeline.insert_before(@pipeline, E, X)
    end
  end

  describe ".upto" do
    test "raises an exception if one can't be found" do
      assert_raise RuntimeError, fn -> Pipeline.upto([], Anything) end
    end

    test "returns the phases upto the match" do
      assert [A, B, C] == Pipeline.upto(@pipeline, C)
      assert [A, B, C, D, {E, [name: "e"]}] == Pipeline.upto(@pipeline, E)
    end

    test "returns the pipeline without specified phase" do
      assert [A, B, D, {E, [name: "e"]}, F] == Pipeline.without(@pipeline, C)
      assert [A, B, C, D, F] == Pipeline.without(@pipeline, E)
    end
  end

  describe ".replace" do
    test "when not found, returns the pipeline unchanged" do
      assert @pipeline == Pipeline.replace(@pipeline, X, ABC)
    end

    test "when found, when the target has options and no replacement options are given, replaces the phase but reuses the options" do
      assert [A, B, C, D, {X, [name: "e"]}, F] == Pipeline.replace(@pipeline, E, X)
    end

    test "when found, when the target has options and replacement options are given, replaces the phase and uses the new options" do
      assert [A, B, C, D, {X, [name: "Custom"]}, F] ==
               Pipeline.replace(@pipeline, E, {X, [name: "Custom"]})

      assert [A, B, C, D, {X, []}, F] == Pipeline.replace(@pipeline, E, {X, []})
    end

    test "when found, when the target has no options, simply replaces the phase" do
      assert [A, B, C, X, {E, [name: "e"]}, F] == Pipeline.replace(@pipeline, D, X)

      assert [A, B, C, {X, [name: "Custom Opt"]}, {E, [name: "e"]}, F] ==
               Pipeline.replace(@pipeline, D, {X, [name: "Custom Opt"]})
    end
  end
end
