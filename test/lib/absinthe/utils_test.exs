defmodule Absinthe.UtilsTest do
  use Absinthe.Case, async: true

  alias Absinthe.Utils

  @snake "foo_bar"
  @preunderscored_snake "__foo_bar"

  describe "camelize with :lower" do

    it "handles normal snake-cased values" do
      assert "fooBar" == Utils.camelize(@snake, lower: true)
    end

    it "handles snake-cased values starting with double underscores" do
      assert "__fooBar" == Utils.camelize(@preunderscored_snake, lower: true)
    end

  end

  describe "camelize without :lower" do

    it "handles normal snake-cased values" do
      assert "FooBar" == Utils.camelize(@snake)
    end

    it "handles snake-cased values starting with double underscores" do
      assert "__FooBar" == Utils.camelize(@preunderscored_snake)
    end

  end

end
