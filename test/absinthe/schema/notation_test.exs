defmodule Absinthe.Schema.NotationTest do
  use Absinthe.Case, async: true

  describe "arg" do
    test "can be under field as an attribute" do
      assert_no_notation_error("ArgFieldValid", """
      object :foo do
        field :picture, :string do
          arg :size, :integer
        end
      end
      """)
    end

    test "can be under directive as an attribute" do
      assert_no_notation_error("ArgDirectiveValid", """
      directive :test do
        arg :if, :boolean

        on :field
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "ArgToplevelInvalid",
        """
        arg :name, :string
        """,
        "Invalid schema notation: `arg` must only be used within `directive`, `field`. Was used in `schema`."
      )
    end
  end

  describe "directive" do
    test "can be toplevel" do
      assert_no_notation_error("DirectiveValid", """
      directive :foo do
        on :field
      end
      """)
    end

    test "cannot be non-toplevel" do
      assert_notation_error(
        "DirectiveInvalid",
        """
        directive :foo do
          directive :bar do
          end
        end
        """,
        "Invalid schema notation: `directive` must only be used toplevel. Was used in `directive`."
      )
    end
  end

  describe "enum" do
    test "can be toplevel" do
      assert_no_notation_error("EnumValid", """
      enum :foo do
      end
      """)
    end

    test "cannot be non-toplevel" do
      assert_notation_error(
        "EnumInvalid",
        """
        enum :foo do
          enum :bar do
          end
        end
        """,
        "Invalid schema notation: `enum` must only be used toplevel. Was used in `enum`."
      )
    end
  end

  describe "field" do
    test "can be under object as an attribute" do
      assert_no_notation_error("FieldObjectValid", """
      object :bar do
        field :name, :string
      end
      """)
    end

    test "can be under input_object as an attribute" do
      assert_no_notation_error("FieldInputObjectValid", """
      input_object :bar do
        field :name, :string
      end
      """)
    end

    test "can be under interface as an attribute" do
      assert_no_notation_error("FieldInterfaceValid", """
      interface :bar do
        field :name, :string
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "FieldToplevelInvalid",
        """
        field :foo, :string
        """,
        "Invalid schema notation: `field` must only be used within `input_object`, `interface`, `object`. Was used in `schema`."
      )
    end
  end

  describe "input_object" do
    test "can be toplevel" do
      assert_no_notation_error("InputObjectValid", """
      input_object :foo do
      end
      """)
    end

    test "cannot be non-toplevel" do
      assert_notation_error(
        "InputObjectInvalid",
        """
        input_object :foo do
          input_object :bar do
          end
        end
        """,
        "Invalid schema notation: `input_object` must only be used toplevel. Was used in `input_object`."
      )
    end
  end

  describe "expand" do
    test "can be under directive as an attribute" do
      assert_no_notation_error("InstructionValid", """
      directive :bar do
        expand fn _, _ -> :ok end
        on :field
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "InstructionToplevelInvalid",
        """
        expand fn _, _ -> :ok end
        """,
        "Invalid schema notation: `expand` must only be used within `directive`. Was used in `schema`."
      )
    end

    test "cannot be within object" do
      assert_notation_error(
        "InstructionObjectInvalid",
        """
        object :foo do
          expand fn _, _ -> :ok end
        end
        """,
        "Invalid schema notation: `expand` must only be used within `directive`. Was used in `object`."
      )
    end
  end

  describe "interface" do
    test "can be toplevel" do
      assert_no_notation_error("InterfaceToplevelValid", """
      interface :foo do
        field :name, :string
        resolve_type fn _, _ -> :bar end
      end
      """)
    end

    test "can be under object as an attribute" do
      assert_no_notation_error("InterfaceObjectValid", """
      interface :foo do
        field :name, :string
        resolve_type fn _, _ -> :bar end
      end
      object :bar do
        interface :foo
        field :name, :string
      end
      """)
    end

    test "cannot be under input_object as an attribute" do
      assert_notation_error(
        "InterfaceInputObjectInvalid",
        """
        interface :foo do
          field :name, :string
          resolve_type fn _, _ -> :bar end
        end
        input_object :bar do
          interface :foo
        end
        """,
        "Invalid schema notation: `interface_attribute` must only be used within `object`, `interface`. Was used in `input_object`."
      )
    end
  end

  describe "interfaces" do
    test "can be under object as an attribute" do
      assert_no_notation_error("ObjectInterfacesValid", """
      interface :bar do
        field :name, :string
        resolve_type fn _, _ -> :foo end
      end
      object :foo do
        field :name, :string
        interfaces [:bar]
      end
      """)
    end

    test "can be under interface as an attribute" do
      assert_no_notation_error("InterfaceInterfacesValid", """
      interface :bar do
        field :name, :string
        resolve_type fn _, _ -> :foo end
      end
      interface :foo do
        field :name, :string
        interfaces [:bar]
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "InterfacesInvalid",
        """
        interface :bar do
          field :name, :string
        end
        interfaces [:bar]
        """,
        "Invalid schema notation: `interfaces` must only be used within `object`, `interface`. Was used in `schema`."
      )
    end
  end

  describe "is_type_of" do
    test "can be under object as an attribute" do
      assert_no_notation_error("IsTypeOfValid", """
      object :bar do
        is_type_of fn _, _ -> true end
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "IsTypeOfToplevelInvalid",
        """
        is_type_of fn _, _ -> true end
        """,
        "Invalid schema notation: `is_type_of` must only be used within `object`. Was used in `schema`."
      )
    end

    test "cannot be within interface" do
      assert_notation_error(
        "IsTypeOfInterfaceInvalid",
        """
        interface :foo do
          is_type_of fn _, _ -> :bar end
        end
        """,
        "Invalid schema notation: `is_type_of` must only be used within `object`. Was used in `interface`."
      )
    end
  end

  describe "object" do
    test "can be toplevel" do
      assert_no_notation_error("ObjectValid", """
      object :foo do
      end
      """)
    end

    test "cannot be non-toplevel" do
      assert_notation_error(
        "ObjectInvalid",
        """
        object :foo do
          object :bar do
          end
        end
        """,
        "Invalid schema notation: `object` must only be used toplevel. Was used in `object`."
      )
    end

    test "cannot use reserved identifiers" do
      assert_notation_error(
        "ReservedIdentifierSubscription",
        """
        object :subscription do
        end
        """,
        "Invalid schema notation: cannot create an `object` with reserved identifier `subscription`"
      )

      assert_notation_error(
        "ReservedIdentifierQuery",
        """
        object :query do
        end
        """,
        "Invalid schema notation: cannot create an `object` with reserved identifier `query`"
      )

      assert_notation_error(
        "ReservedIdentifierMutation",
        """
        object :mutation do
        end
        """,
        "Invalid schema notation: cannot create an `object` with reserved identifier `mutation`"
      )
    end
  end

  describe "on" do
    test "can be under directive as an attribute" do
      assert_no_notation_error("OnValid", """
      directive :foo do
        on [:fragment_spread, :mutation]
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "OnInvalid",
        """
        on [:fragment_spread, :mutation]
        """,
        "Invalid schema notation: `on` must only be used within `directive`. Was used in `schema`."
      )
    end
  end

  describe "parse" do
    test "can be under scalar as an attribute" do
      assert_no_notation_error("ParseValid", """
      scalar :foo do
        parse &(&1)
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "ParseInvalid",
        """
        parse &(&1)
        """,
        "Invalid schema notation: `parse` must only be used within `scalar`. Was used in `schema`."
      )
    end
  end

  describe "resolve" do
    test "can be under field as an attribute" do
      assert_no_notation_error("ResolveValid", """
      object :bar do
        field :foo, :integer do
          resolve fn _, _, _ -> {:ok, 1} end
        end
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "ResolveInvalid",
        """
        resolve fn _, _ -> {:ok, 1} end
        """,
        "Invalid schema notation: `resolve` must only be used within `field`. Was used in `schema`."
      )
    end

    test "cannot be within object" do
      assert_notation_error(
        "ResolveInvalid2",
        """
        object :foo do
          resolve fn _, _ -> {:ok, 1} end
        end
        """,
        "Invalid schema notation: `resolve` must only be used within `field`. Was used in `object`."
      )
    end
  end

  describe "resolve_type" do
    test "can be under interface as an attribute" do
      assert_no_notation_error("ResolveTypeValidInterface", """
      interface :bar do
        resolve_type fn _, _ -> :baz end
      end
      """)
    end

    test "can be under union as an attribute" do
      assert_no_notation_error("ResolveTypeValidUnion", """
        union :bar do
          resolve_type fn _, _ -> :baz end
        end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "ResolveTypeInvalidToplevel",
        """
        resolve_type fn _, _ -> :bar end
        """,
        "Invalid schema notation: `resolve_type` must only be used within `interface`, `union`. Was used in `schema`."
      )
    end

    test "cannot be within object" do
      assert_notation_error(
        "ResolveTypeInvalidObject",
        """
        object :foo do
          resolve_type fn _, _ -> :bar end
        end
        """,
        "Invalid schema notation: `resolve_type` must only be used within `interface`, `union`. Was used in `object`."
      )
    end
  end

  describe "scalar" do
    test "can be toplevel" do
      assert_no_notation_error("ScalarValid", """
      scalar :foo do
      end
      """)
    end

    test "cannot be non-toplevel" do
      assert_notation_error(
        "ScalarInvalid",
        """
        scalar :foo do
          scalar :bar do
          end
        end
        """,
        "Invalid schema notation: `scalar` must only be used toplevel. Was used in `scalar`."
      )
    end
  end

  describe "serialize" do
    test "can be under scalar as an attribute" do
      assert_no_notation_error("SerializeValid", """
      scalar :foo do
        serialize &(&1)
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "SerializeInvalid",
        """
        serialize &(&1)
        """,
        "Invalid schema notation: `serialize` must only be used within `scalar`. Was used in `schema`."
      )
    end
  end

  describe "types" do
    test "can be under union as an attribute" do
      assert_no_notation_error("TypesValid", """
      object :audi do
      end
      object :volvo do
      end
      union :brand do
        types [:audi, :volvo]
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "TypesInvalid",
        "types [:foo]",
        "Invalid schema notation: `types` must only be used within `union`. Was used in `schema`."
      )
    end
  end

  describe "value" do
    test "can be under enum as an attribute" do
      assert_no_notation_error("ValueValid", """
      enum :color do
        value :red
        value :green
        value :blue
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "ValueInvalid",
        "value :b",
        "Invalid schema notation: `value` must only be used within `enum`. Was used in `schema`."
      )
    end
  end

  describe "description" do
    test "can be under object as an attribute" do
      assert_no_notation_error("DescriptionValid", """
      object :item do
        description \"""
        Here's a description
        \"""
      end
      """)
    end

    test "cannot be toplevel" do
      assert_notation_error(
        "DescriptionInvalid",
        ~s(description "test"),
        "Invalid schema notation: `description` must not be used toplevel. Was used in `schema`."
      )
    end
  end

  test "No nested non_null" do
    assert_notation_error(
      "NestedNonNull",
      """
      object :really_null do
        field :foo, non_null(non_null(:string))
      end
      """,
      "Invalid schema notation: `non_null` must not be nested"
    )
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
    assert_raise(Absinthe.Schema.Notation.Error, message, fn ->
      """
      defmodule MyTestSchema.#{name} do
        use Absinthe.Schema

        query do
          #Query type must exist
        end

        #{text}
      end
      """
      |> Code.eval_string()
    end)
  end

  def assert_no_notation_error(name, text) do
    assert """
           defmodule MyTestSchema.#{name} do
             use Absinthe.Schema

             query do
               #Query type must exist
             end

             #{text}
           end
           """
           |> Code.eval_string()
  end
end
