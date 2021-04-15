defmodule Absinthe.Integration.Execution.SerializationTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :bad_integer, :integer do
        resolve fn _, _, _ -> {:ok, 1.0} end
      end

      field :bad_float, :float do
        resolve fn _, _, _ -> {:ok, "1"} end
      end

      field :bad_boolean, :boolean do
        resolve fn _, _, _ -> {:ok, "true"} end
      end

      field :bad_string, :string do
        resolve fn _, _, _ -> {:ok, %{}} end
      end
    end
  end

  @query """
  query { badInteger }
  """
  test "returning not an integer for an integer raises" do
    assert_raise(Absinthe.SerializationError, fn ->
      Absinthe.run(@query, Schema)
    end)
  end

  @query """
  query { badFloat }
  """
  test "returning not a float for a float raises" do
    assert_raise(Absinthe.SerializationError, fn ->
      Absinthe.run(@query, Schema)
    end)
  end

  @query """
  query { badBoolean }
  """
  test "returning not a boolean for a boolean raises" do
    assert_raise(Absinthe.SerializationError, fn ->
      Absinthe.run(@query, Schema)
    end)
  end

  @query """
  query { badString }
  """
  test "returning not a string for a string raises" do
    assert_raise(Absinthe.SerializationError, fn ->
      Absinthe.run(@query, Schema)
    end)
  end
end
