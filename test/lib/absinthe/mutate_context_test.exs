defmodule Absinthe.MutateContextTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    @foo %{bar: 42}

    object :foo do
      field :bar, :integer
      field :context_value, :integer do
        resolve fn _, info -> {:ok, info.context[:context_value]} end
      end
      field :change_context_forbidden, :integer do
        resolve fn _, info ->
          {:ok, 0, Map.put(info.context, :context_value, 10)}
        end
      end
    end

    query do
      field :change_context_forbidden, :foo do
        resolve fn _, info ->
          {:ok, @foo, Map.put(info.context, :context_value, 7)}
        end
      end
    end

    mutation do
      field :default, :foo, resolve: fn _, _ -> {:ok, @foo} end
      field :change_context, :foo do
        resolve fn _, info ->
          {:ok, @foo, Map.put(info.context, :context_value, 7)}
        end
      end
    end
  end

  test "it handles changes to the context returned from mutatuons" do
    doc = """
    mutation {
      default {
        bar
        contextValue
      }
    }
    """
    assert {:ok, %{data: %{"default" => %{"bar" => 42, "contextValue" => nil}}}} == Absinthe.run(doc, Schema)

    doc = """
    mutation {
      changeContext {
        bar
        contextValue
      }
    }
    """
    assert {:ok, %{data: %{"changeContext" => %{"bar" => 42, "contextValue" => 7}}}} == Absinthe.run(doc, Schema)
  end

  test "it forbids context changes on non mutation fields" do
    doc = """
    query {
      changeContextForbidden {
        bar
        contextValue
      }
    }
    """
    assert_raise Absinthe.ExecutionError, fn -> Absinthe.run(doc, Schema) end

    doc = """
    mutation {
      default {
        bar
        contextValue
        changeContextForbidden
      }
    }
    """
    assert_raise Absinthe.ExecutionError, fn -> Absinthe.run(doc, Schema) end
  end

end
