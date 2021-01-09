defmodule Absinthe.Subscription.PipelineSerializerTest do
  use ExUnit.Case, async: true

  alias Absinthe.Pipeline
  alias Absinthe.Subscription.PipelineSerializer

  defmodule Schema do
    use Absinthe.Schema

    query do
      # Query type must exist
    end
  end

  describe "pack/1" do
    test "packs full-fledged pipeline successfully" do
      pipeline = Pipeline.for_document(Schema, some: :option)

      assert {:packed, [_ | _], %{{:options, 0} => options}} = PipelineSerializer.pack(pipeline)
      assert options[:some] == :option
    end

    test "packs with correct mapping of unique options sets" do
      pipeline = [
        {Phase1, [option1: :value1]},
        Phase2,
        {Phase3, [option2: :value2]},
        {Phase4, [option1: :value1]}
      ]

      assert {:packed,
              [
                {Phase1, {:options, 0}},
                Phase2,
                {Phase3, {:options, 1}},
                {Phase4, {:options, 0}}
              ],
              %{{:options, 0} => [option1: :value1], {:options, 1} => [option2: :value2]}} =
               PipelineSerializer.pack(pipeline)
    end
  end

  describe "unpack/1" do
    test "unpacks full-fledged pipeline successfully" do
      packed_pipeline =
        Schema
        |> Pipeline.for_document(some: :option)
        |> PipelineSerializer.pack()

      assert [_ | _] = PipelineSerializer.unpack(packed_pipeline)
    end

    test "leaves unpacked pipeline intact" do
      pipeline = Pipeline.for_document(Schema, some: :option)

      assert PipelineSerializer.unpack(pipeline) == pipeline
    end

    test "unpacks with correct options in right spots" do
      pipeline = [
        {Phase1, [option1: :value1]},
        Phase2,
        {Phase3, [option2: :value2]},
        {Phase4, [option1: :value1]}
      ]

      unpacked =
        pipeline
        |> PipelineSerializer.pack()
        |> PipelineSerializer.unpack()

      assert unpacked == pipeline
    end
  end

  test "flattens nested pipeline in full pack/unpack cycle" do
    pipeline = [
      {Phase1, [option1: :value1]},
      Phase2,
      [{Phase3, [option2: :value2]}, {Phase4, [option1: :value1]}]
    ]

    unpacked =
      pipeline
      |> PipelineSerializer.pack()
      |> PipelineSerializer.unpack()

    assert unpacked == [
             {Phase1, [option1: :value1]},
             Phase2,
             {Phase3, [option2: :value2]},
             {Phase4, [option1: :value1]}
           ]
  end
end
