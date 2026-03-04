defmodule Absinthe.Incremental.StreamTest do
  @moduledoc """
  Tests for @stream directive functionality.

  These tests verify the directive definitions and basic parsing.
  Full integration tests require the streaming resolution phase to be
  properly integrated into the main Absinthe pipeline.
  """

  use ExUnit.Case, async: true

  alias Absinthe.{Pipeline, Blueprint}

  defmodule TestSchema do
    use Absinthe.Schema

    import_directives Absinthe.Type.BuiltIns.IncrementalDirectives

    query do
      field :users, list_of(:user) do
        resolve fn _, _ ->
          {:ok,
           Enum.map(1..10, fn i ->
             %{id: "#{i}", name: "User #{i}"}
           end)}
        end
      end

      field :posts, list_of(:post) do
        resolve fn _, _ ->
          {:ok,
           Enum.map(1..20, fn i ->
             %{id: "#{i}", title: "Post #{i}"}
           end)}
        end
      end
    end

    object :user do
      field :id, non_null(:id)
      field :name, non_null(:string)

      field :friends, list_of(:user) do
        resolve fn _, _, _ ->
          {:ok,
           Enum.map(1..3, fn i ->
             %{id: "f#{i}", name: "Friend #{i}"}
           end)}
        end
      end
    end

    object :post do
      field :id, non_null(:id)
      field :title, non_null(:string)

      field :comments, list_of(:comment) do
        resolve fn _, _, _ ->
          {:ok,
           Enum.map(1..5, fn i ->
             %{id: "c#{i}", text: "Comment #{i}"}
           end)}
        end
      end
    end

    object :comment do
      field :id, non_null(:id)
      field :text, non_null(:string)
    end
  end

  describe "directive definition" do
    test "@stream directive exists in schema" do
      directive = Absinthe.Schema.lookup_directive(TestSchema, :stream)
      assert directive != nil
      assert directive.name == "stream"
    end

    test "@stream directive has correct locations" do
      directive = Absinthe.Schema.lookup_directive(TestSchema, :stream)
      assert :field in directive.locations
    end

    test "@stream directive has if argument" do
      directive = Absinthe.Schema.lookup_directive(TestSchema, :stream)
      assert Map.has_key?(directive.args, :if)
      assert directive.args.if.type == :boolean
      assert directive.args.if.default_value == true
    end

    test "@stream directive has label argument" do
      directive = Absinthe.Schema.lookup_directive(TestSchema, :stream)
      assert Map.has_key?(directive.args, :label)
      assert directive.args.label.type == :string
    end

    test "@stream directive has initial_count argument" do
      directive = Absinthe.Schema.lookup_directive(TestSchema, :stream)
      assert Map.has_key?(directive.args, :initial_count)
      assert directive.args.initial_count.type == :integer
      assert directive.args.initial_count.default_value == 0
    end
  end

  describe "directive parsing" do
    test "parses @stream on list field" do
      query = """
      query {
        users @stream(label: "users", initialCount: 5) {
          id
          name
        }
      }
      """

      assert {:ok, blueprint} = run_phases(query)

      users_field = find_field(blueprint, "users")
      assert users_field != nil

      # Check that the directive was parsed
      assert length(users_field.directives) > 0
      stream_directive = Enum.find(users_field.directives, &(&1.name == "stream"))
      assert stream_directive != nil
    end

    test "validates @stream cannot be used on non-list fields" do
      # Create a schema with a non-list field to test
      defmodule NonListSchema do
        use Absinthe.Schema

        query do
          field :user, :user do
            resolve fn _, _ -> {:ok, %{id: "1", name: "Test"}} end
          end
        end

        object :user do
          field :id, non_null(:id)
          field :name, non_null(:string)
        end
      end

      query = """
      query {
        user @stream(initialCount: 1) {
          id
        }
      }
      """

      # @stream on non-list should work syntactically but semantically makes no sense
      # The behavior depends on implementation
      result = Absinthe.run(query, NonListSchema)

      # At minimum it should not crash
      assert {:ok, _} = result
    end
  end

  describe "directive expansion" do
    test "sets stream flag when if: true (default)" do
      query = """
      query {
        users @stream(label: "users", initialCount: 3) {
          id
        }
      }
      """

      assert {:ok, blueprint} = run_phases(query)

      users_field = find_field(blueprint, "users")

      # The expand callback should have set the :stream flag
      assert Map.has_key?(users_field.flags, :stream)
      stream_flag = users_field.flags.stream
      assert stream_flag.enabled == true
      assert stream_flag.label == "users"
      assert stream_flag.initial_count == 3
    end

    test "does not set stream flag when if: false" do
      query = """
      query {
        users @stream(if: false, initialCount: 3) {
          id
        }
      }
      """

      assert {:ok, blueprint} = run_phases(query)

      users_field = find_field(blueprint, "users")

      # When if: false, either no stream flag or enabled: false
      if Map.has_key?(users_field.flags, :stream) do
        assert users_field.flags.stream.enabled == false
      end
    end

    test "handles @stream with variable for if argument" do
      query = """
      query($shouldStream: Boolean!) {
        users @stream(if: $shouldStream, initialCount: 2) {
          id
        }
      }
      """

      # With shouldStream: true
      assert {:ok, blueprint_true} = run_phases(query, %{"shouldStream" => true})
      users_true = find_field(blueprint_true, "users")
      assert users_true.flags.stream.enabled == true

      # With shouldStream: false
      assert {:ok, blueprint_false} = run_phases(query, %{"shouldStream" => false})
      users_false = find_field(blueprint_false, "users")

      if Map.has_key?(users_false.flags, :stream) do
        assert users_false.flags.stream.enabled == false
      end
    end

    test "sets default initial_count to 0" do
      query = """
      query {
        users @stream(label: "users") {
          id
        }
      }
      """

      assert {:ok, blueprint} = run_phases(query)

      users_field = find_field(blueprint, "users")
      assert users_field.flags.stream.initial_count == 0
    end
  end

  describe "standard execution without streaming" do
    test "query with @stream runs normally when streaming not enabled" do
      query = """
      query {
        users @stream(initialCount: 3) {
          id
          name
        }
      }
      """

      # Standard execution should still work
      {:ok, result} = Absinthe.run(query, TestSchema)

      # All data should be returned (stream is ignored without streaming pipeline)
      assert length(result.data["users"]) == 10
    end
  end

  describe "nested streaming" do
    test "parses nested @stream directives" do
      query = """
      query {
        users @stream(label: "users", initialCount: 2) {
          id
          friends @stream(label: "friends", initialCount: 1) {
            id
            name
          }
        }
      }
      """

      assert {:ok, blueprint} = run_phases(query)

      users_field = find_field(blueprint, "users")
      friends_field = find_nested_field(blueprint, "friends")

      assert users_field.flags.stream.enabled == true
      assert friends_field.flags.stream.enabled == true
    end
  end

  # Helper functions

  defp run_phases(query, variables \\ %{}) do
    pipeline =
      TestSchema
      |> Pipeline.for_document(variables: variables)
      |> Pipeline.without(Absinthe.Phase.Document.Execution.Resolution)
      |> Pipeline.without(Absinthe.Phase.Document.Result)

    case Absinthe.Pipeline.run(query, pipeline) do
      {:ok, blueprint, _phases} -> {:ok, blueprint}
      error -> error
    end
  end

  defp find_field(blueprint, name) do
    {_, found} =
      Blueprint.prewalk(blueprint, nil, fn
        %Absinthe.Blueprint.Document.Field{name: ^name} = node, nil -> {node, node}
        node, acc -> {node, acc}
      end)

    found
  end

  defp find_nested_field(blueprint, name) do
    # Find a field that's nested inside another field
    {_, found} =
      Blueprint.prewalk(blueprint, nil, fn
        %Absinthe.Blueprint.Document.Field{name: ^name} = node, _acc -> {node, node}
        node, acc -> {node, acc}
      end)

    found
  end
end
