defmodule Absinthe.Schema.NotationTest do
  use ExSpec, async: true

  describe "arg" do
    it "can be under field or directive as an attribute" do
    end
  end

  describe "directive" do
    it "can be toplevel" do
    end
  end

  describe "enum" do
    it "can be under query or mutation or subscription as a type" do
    end
  end

  describe "field" do
    it "can be under object and interface as an attribute" do
    end
  end

  describe "input_object" do
    it "can be under query or mutation or subscription as a type" do
    end
  end

  describe "instruction" do
    it "can be under directive as an attribute" do
    end
  end

  describe "interface" do
    it "can be under query or mutation or subscription as a type" do
    end
    it "can be under object as an attribute" do
    end
  end

  describe "interfaces" do
    it "can be under object as an attribute" do
    end
  end

  describe "is_type_of" do
    it "can be under object as an attribute" do
    end
  end

  describe "object" do
    it "can be under query or mutation or subscription as a type" do
    end
  end

  describe "on" do
    it "can be under directive as an attribute" do
    end
  end

  describe "parse" do
    it "can be under scalar as an attribute" do
    end
  end

  describe "resolve" do
    it "can be under field as an attribute" do
    end
  end

  describe "resolve_type" do
    it "can be under interface or union as an attribute" do
    end
  end

  describe "scalar" do
    it "can be toplevel" do
    end
  end

  describe "serialize" do
    it "can be under scalar as an attribute" do
    end
  end

  describe "types" do
    it "can be under union as an attribute" do
      assert_no_notation_error "TypesValid", """
      union :brand do
        types [:audi, :volvo]
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "TypesInvalid", "types [:foo]", "Invalid schema notation: `types` must only be used within `union`"
    end
  end

  describe "value" do
    it "can be under enum as an attribute" do
      assert_no_notation_error "ValueValid", """
      enum :color do
        value :red
        value :green
        value :blue
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "ValueInvalid", "value :b", "Invalid schema notation: `value` must only be used within `enum`"
    end
  end

  @doc """
  Assert a notation error occurs.

  ## Examples

  ```
  iex> assert_notation_error(\"""
  object :bar do
    field :name, :string
  end
  \""")
  ```
  """
  def assert_notation_error(name, text, message) do
    err = assert_raise(Absinthe.Schema.Notation.Error, message, fn ->
      """
      defmodule MyTestSchema.#{name} do
        use Absinthe.Schema
        #{text}
      end
      """
      |> Code.eval_string
    end)
  end

  def assert_no_notation_error(name, text) do
    """
    defmodule MyTestSchema.#{name} do
      use Absinthe.Schema
      #{text}
    end
    """
    |> Code.eval_string
  end

end
