defmodule Absinthe.UtilsTest do
  use Absinthe.Case, async: true

  alias Absinthe.Utils

  @snake "foo_bar"
  @preunderscored_snake "__foo_bar"

  describe "camelize with :lower" do
    test "handles normal snake-cased values" do
      assert "fooBar" == Utils.camelize(@snake, lower: true)
    end

    test "handles snake-cased values starting with double underscores" do
      assert "__fooBar" == Utils.camelize(@preunderscored_snake, lower: true)
    end
  end

  describe "camelize without :lower" do
    test "handles normal snake-cased values" do
      assert "FooBar" == Utils.camelize(@snake)
    end

    test "handles snake-cased values starting with double underscores" do
      assert "__FooBar" == Utils.camelize(@preunderscored_snake)
    end
  end

  defmodule Schema do
    use Absinthe.Schema.Notation

    object :blah do
      field :foo, :string
    end

    object :bar do
      field :blah, :string
    end
  end

  test "prewalking and postwalking result in the same number" do
    blueprint = Schema.__absinthe_blueprint__()

    count = fn node, acc ->
      send(self(), :tick)
      {node, acc + 1}
    end

    {_, prewalk_count} = Absinthe.Blueprint.prewalk(blueprint, 0, count)
    prewalk_exec_count = count_ticks()

    {_, postwalk_count} = Absinthe.Blueprint.postwalk(blueprint, 0, count)
    postwalk_exec_count = count_ticks()

    assert prewalk_count == prewalk_exec_count
    assert postwalk_count == postwalk_exec_count
    assert prewalk_count == postwalk_count
  end

  defp count_ticks(count \\ 0) do
    receive do
      :tick -> count_ticks(count + 1)
    after
      0 ->
        count
    end
  end
end
