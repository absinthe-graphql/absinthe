defmodule Absinthe.Phase.Execution.NonNullSuspendedTest do
  # Non-null propagation must behave identically whether a field resolves
  # synchronously or suspends (batch/async) and resolves in a later resolution
  # pass. These tests run the same document in each mode and require identical
  # results.

  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    import Absinthe.Resolution.Helpers, only: [batch: 3, async: 1]

    enum :mode do
      value :sync
      value :batch
      value :async
    end

    object :thing do
      field :name, non_null(:string), resolve: &__MODULE__.resolve_name/3
      field :nullable_name, :string, resolve: &__MODULE__.resolve_name/3

      # Nullable scalar list.
      field :tags, list_of(:string), resolve: &__MODULE__.resolve_tags/3

      # Non-null elements: keeps the per-element form and must null out the
      # whole list when an element is nil.
      field :strict_tags, list_of(non_null(:string)), resolve: &__MODULE__.resolve_tags/3
    end

    object :inner do
      field :thing, non_null(:thing) do
        resolve fn %{mode: mode}, _, _ -> {:ok, %{id: :nil_thing, mode: mode}} end
      end
    end

    object :chain do
      field :child, non_null(:thing) do
        resolve fn
          %{mode: :sync}, _, _ ->
            {:ok, %{id: :nil_thing, mode: :sync}}

          %{mode: :batch}, _, _ ->
            batch({__MODULE__, :children}, :batch, fn _ ->
              {:ok, %{id: :nil_thing, mode: :batch}}
            end)

          %{mode: :async}, _, _ ->
            async(fn -> {:ok, %{id: :nil_thing, mode: :async}} end)
        end
      end
    end

    query do
      field :thing, :thing do
        arg :mode, non_null(:mode)
        resolve fn _, %{mode: mode}, _ -> {:ok, %{id: :nil_thing, mode: mode}} end
      end

      field :deep, :inner do
        arg :mode, non_null(:mode)
        resolve fn _, %{mode: mode}, _ -> {:ok, %{mode: mode}} end
      end

      field :things, list_of(non_null(:thing)) do
        arg :mode, non_null(:mode)

        resolve fn _, %{mode: mode}, _ ->
          {:ok, [%{id: 1, mode: mode}, %{id: :nil_thing, mode: mode}]}
        end
      end

      field :ok_things, list_of(non_null(:thing)) do
        arg :mode, non_null(:mode)

        resolve fn _, %{mode: mode}, _ ->
          {:ok, [%{id: 1, mode: mode}, %{id: 2, mode: mode}]}
        end
      end

      field :chain, :chain do
        arg :mode, non_null(:mode)
        resolve fn _, %{mode: mode}, _ -> {:ok, %{mode: mode}} end
      end
    end

    def resolve_name(%{id: id, mode: :sync}, _, _) do
      {:ok, name_for(id)}
    end

    def resolve_name(%{id: id, mode: :batch}, _, _) do
      batch({__MODULE__, :names}, id, fn results ->
        {:ok, Map.get(results, id)}
      end)
    end

    def resolve_name(%{id: id, mode: :async}, _, _) do
      async(fn -> {:ok, name_for(id)} end)
    end

    def resolve_tags(%{id: id, mode: :sync}, _, _) do
      {:ok, tags_for(id)}
    end

    def resolve_tags(%{id: id, mode: :batch}, _, _) do
      batch({__MODULE__, :tags}, id, fn results ->
        {:ok, Map.get(results, id)}
      end)
    end

    def resolve_tags(%{id: id, mode: :async}, _, _) do
      async(fn -> {:ok, tags_for(id)} end)
    end

    def names(_, ids), do: Map.new(ids, &{&1, name_for(&1)})

    def tags(_, ids), do: Map.new(ids, &{&1, tags_for(&1)})

    defp tags_for(id), do: ["a-#{id}", nil, "b-#{id}"]

    def children(_, _), do: %{}

    defp name_for(:nil_thing), do: nil
    defp name_for(id), do: "thing-#{id}"
  end

  defp assert_all_modes_agree(query, expected_data) do
    results =
      for mode <- ~w(SYNC BATCH ASYNC) do
        {mode, Absinthe.run!(query, Schema, variables: %{"mode" => mode})}
      end

    for {mode, result} <- results do
      assert result.data == expected_data, "data mismatch in #{mode} mode: #{inspect(result)}"
    end

    [{_, sync} | rest] = results

    for {mode, result} <- rest do
      assert result == sync, "#{mode} mode result differs from SYNC: #{inspect(result)}"
    end

    sync
  end

  test "fully resolved values are identical across modes" do
    result =
      assert_all_modes_agree(
        """
        query ($mode: Mode!) { okThings(mode: $mode) { name nullableName } }
        """,
        %{
          "okThings" => [
            %{"name" => "thing-1", "nullableName" => "thing-1"},
            %{"name" => "thing-2", "nullableName" => "thing-2"}
          ]
        }
      )

    refute Map.has_key?(result, :errors)
  end

  test "nil in a non-null field nullifies the parent object across modes" do
    result =
      assert_all_modes_agree(
        """
        query ($mode: Mode!) { thing(mode: $mode) { name } }
        """,
        %{"thing" => nil}
      )

    assert [%{message: "Cannot return null for non-nullable field", path: ["thing", "name"]}] =
             result.errors
  end

  test "nil non-null leaf under a nullable leaf sibling across modes" do
    result =
      assert_all_modes_agree(
        """
        query ($mode: Mode!) { thing(mode: $mode) { name nullableName } }
        """,
        %{"thing" => nil}
      )

    assert [%{path: ["thing", "name"]}] = result.errors
  end

  test "non-null propagation crosses multiple object levels across modes" do
    result =
      assert_all_modes_agree(
        """
        query ($mode: Mode!) { deep(mode: $mode) { thing { name } } }
        """,
        %{"deep" => nil}
      )

    assert [%{path: ["deep", "thing", "name"]}] = result.errors
  end

  test "nil non-null element nullifies a list of non-null objects across modes" do
    result =
      assert_all_modes_agree(
        """
        query ($mode: Mode!) { things(mode: $mode) { name } }
        """,
        %{"things" => nil}
      )

    assert [%{path: ["things", 1, "name"]}] = result.errors
  end

  test "nullable scalar lists are identical across modes" do
    result =
      assert_all_modes_agree(
        """
        query ($mode: Mode!) { okThings(mode: $mode) { nullableName tags } }
        """,
        %{
          "okThings" => [
            %{"nullableName" => "thing-1", "tags" => ["a-1", nil, "b-1"]},
            %{"nullableName" => "thing-2", "tags" => ["a-2", nil, "b-2"]}
          ]
        }
      )

    refute Map.has_key?(result, :errors)
  end

  test "nil element in a list of non-null scalars nullifies the list across modes" do
    result =
      assert_all_modes_agree(
        """
        query ($mode: Mode!) { okThings(mode: $mode) { nullableName strictTags } }
        """,
        %{
          "okThings" => [
            %{"nullableName" => "thing-1", "strictTags" => nil},
            %{"nullableName" => "thing-2", "strictTags" => nil}
          ]
        }
      )

    assert [
             %{path: ["okThings", 0, "strictTags", 1]},
             %{path: ["okThings", 1, "strictTags", 1]}
           ] = Enum.sort_by(result.errors, & &1.path)
  end

  test "propagation through chained suspensions across modes" do
    result =
      assert_all_modes_agree(
        """
        query ($mode: Mode!) { chain(mode: $mode) { child { name } } }
        """,
        %{"chain" => nil}
      )

    assert [%{path: ["chain", "child", "name"]}] = result.errors
  end
end
