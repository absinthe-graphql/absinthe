defmodule Absinthe.Incremental.DeferTest do
  @moduledoc """
  Tests for @defer directive functionality.

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
      field :user, :user do
        arg :id, non_null(:id)

        resolve fn %{id: id}, _ ->
          {:ok,
           %{
             id: id,
             name: "User #{id}",
             email: "user#{id}@example.com"
           }}
        end
      end

      field :users, list_of(:user) do
        resolve fn _, _ ->
          {:ok,
           [
             %{id: "1", name: "User 1", email: "user1@example.com"},
             %{id: "2", name: "User 2", email: "user2@example.com"},
             %{id: "3", name: "User 3", email: "user3@example.com"}
           ]}
        end
      end
    end

    object :user do
      field :id, non_null(:id)
      field :name, non_null(:string)
      field :email, non_null(:string)

      field :profile, :profile do
        resolve fn user, _, _ ->
          {:ok,
           %{
             bio: "Bio for #{user.name}",
             avatar: "avatar_#{user.id}.jpg",
             followers: 100
           }}
        end
      end

      field :posts, list_of(:post) do
        resolve fn user, _, _ ->
          {:ok,
           [
             %{id: "p1", title: "Post 1 by #{user.name}"},
             %{id: "p2", title: "Post 2 by #{user.name}"}
           ]}
        end
      end
    end

    object :profile do
      field :bio, :string
      field :avatar, :string
      field :followers, :integer
    end

    object :post do
      field :id, non_null(:id)
      field :title, non_null(:string)
    end
  end

  describe "directive definition" do
    test "@defer directive exists in schema" do
      directive = Absinthe.Schema.lookup_directive(TestSchema, :defer)
      assert directive != nil
      assert directive.name == "defer"
    end

    test "@defer directive has correct locations" do
      directive = Absinthe.Schema.lookup_directive(TestSchema, :defer)
      assert :fragment_spread in directive.locations
      assert :inline_fragment in directive.locations
    end

    test "@defer directive has if argument" do
      directive = Absinthe.Schema.lookup_directive(TestSchema, :defer)
      assert Map.has_key?(directive.args, :if)
      assert directive.args.if.type == :boolean
      assert directive.args.if.default_value == true
    end

    test "@defer directive has label argument" do
      directive = Absinthe.Schema.lookup_directive(TestSchema, :defer)
      assert Map.has_key?(directive.args, :label)
      assert directive.args.label.type == :string
    end
  end

  describe "directive parsing" do
    test "parses @defer on fragment spread" do
      query = """
      query {
        user(id: "1") {
          id
          ...UserProfile @defer(label: "profile")
        }
      }

      fragment UserProfile on User {
        name
        email
      }
      """

      assert {:ok, blueprint} = run_phases(query)

      # Find the fragment spread with the defer directive
      fragment_spread = find_node(blueprint, Absinthe.Blueprint.Document.Fragment.Spread)
      assert fragment_spread != nil

      # Check that the directive was parsed
      assert length(fragment_spread.directives) > 0
      defer_directive = Enum.find(fragment_spread.directives, &(&1.name == "defer"))
      assert defer_directive != nil
    end

    test "parses @defer on inline fragment" do
      query = """
      query {
        user(id: "1") {
          id
          ... @defer(label: "details") {
            name
            email
          }
        }
      }
      """

      assert {:ok, blueprint} = run_phases(query)

      # Find the inline fragment
      inline_fragment = find_node(blueprint, Absinthe.Blueprint.Document.Fragment.Inline)
      assert inline_fragment != nil

      # Check the directive
      defer_directive = Enum.find(inline_fragment.directives, &(&1.name == "defer"))
      assert defer_directive != nil
    end

    test "validates @defer cannot be used on fields" do
      # @defer should only be valid on fragments
      query = """
      query {
        user(id: "1") @defer {
          id
        }
      }
      """

      # This should produce a validation error
      result = Absinthe.run(query, TestSchema)
      assert {:ok, %{errors: errors}} = result
      assert length(errors) > 0
    end
  end

  describe "directive expansion" do
    test "sets defer flag when if: true (default)" do
      query = """
      query {
        user(id: "1") {
          id
          ... @defer(label: "profile") {
            name
          }
        }
      }
      """

      assert {:ok, blueprint} = run_phases(query)

      inline_fragment = find_node(blueprint, Absinthe.Blueprint.Document.Fragment.Inline)

      # The expand callback should have set the :defer flag
      assert Map.has_key?(inline_fragment.flags, :defer)
      defer_flag = inline_fragment.flags.defer
      assert defer_flag.enabled == true
      assert defer_flag.label == "profile"
    end

    test "does not set defer flag when if: false" do
      query = """
      query {
        user(id: "1") {
          id
          ... @defer(if: false, label: "disabled") {
            name
          }
        }
      }
      """

      assert {:ok, blueprint} = run_phases(query)

      inline_fragment = find_node(blueprint, Absinthe.Blueprint.Document.Fragment.Inline)

      # When if: false, either no defer flag or enabled: false
      if Map.has_key?(inline_fragment.flags, :defer) do
        assert inline_fragment.flags.defer.enabled == false
      end
    end

    test "handles @defer with variable for if argument" do
      query = """
      query($shouldDefer: Boolean!) {
        user(id: "1") {
          id
          ... @defer(if: $shouldDefer, label: "conditional") {
            name
          }
        }
      }
      """

      # With shouldDefer: true
      assert {:ok, blueprint_true} = run_phases(query, %{"shouldDefer" => true})
      inline_true = find_node(blueprint_true, Absinthe.Blueprint.Document.Fragment.Inline)
      assert inline_true.flags.defer.enabled == true

      # With shouldDefer: false
      assert {:ok, blueprint_false} = run_phases(query, %{"shouldDefer" => false})
      inline_false = find_node(blueprint_false, Absinthe.Blueprint.Document.Fragment.Inline)

      if Map.has_key?(inline_false.flags, :defer) do
        assert inline_false.flags.defer.enabled == false
      end
    end
  end

  describe "standard execution without streaming" do
    test "query with @defer runs normally when streaming not enabled" do
      query = """
      query {
        user(id: "1") {
          id
          ... @defer(label: "profile") {
            name
            email
          }
        }
      }
      """

      # Standard execution should still work
      {:ok, result} = Absinthe.run(query, TestSchema)

      # All data should be returned (defer is ignored without streaming pipeline)
      assert result.data["user"]["id"] == "1"
      assert result.data["user"]["name"] == "User 1"
      assert result.data["user"]["email"] == "user1@example.com"
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

  defp find_node(blueprint, type) do
    {_, found} =
      Blueprint.prewalk(blueprint, nil, fn
        %{__struct__: ^type} = node, nil -> {node, node}
        node, acc -> {node, acc}
      end)

    found
  end
end
