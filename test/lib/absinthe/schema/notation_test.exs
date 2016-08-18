defmodule Absinthe.Schema.NotationTest do
  use Absinthe.Case, async: true

  describe "import fields" do
    it "fields can be imported" do
      defmodule Foo do
        use Absinthe.Schema.Notation

        object :foo do
          field :name, :string
        end

        object :bar do
          import_fields :foo
          field :email, :string
        end
      end

      assert [:email, :name] = Foo.__absinthe_type__(:bar).fields |> Map.keys |> Enum.sort
    end

    it "can work transitively" do
      defmodule Bar do
        use Absinthe.Schema.Notation

        object :foo do
          field :name, :string
        end

        object :bar do
          import_fields :foo
          field :email, :string
        end

        object :baz do
          import_fields :bar
          field :age, :integer
        end
      end

      assert [:age, :email, :name] == Bar.__absinthe_type__(:baz).fields |> Map.keys |> Enum.sort
    end

    it "raises errors nicely" do
      defmodule ErrorSchema do
        use Absinthe.Schema.Notation

        object :bar do
          import_fields :asdf
          field :email, :string
        end
      end

      assert [error] = ErrorSchema.__absinthe_errors__
      assert error == %{data: %{artifact: "Field Import Erro\n\nObject :bar imports fields from :asdf but\n:asdf does not exist in the schema!", value: :asdf}, location: %{file: __ENV__.file, line: 48}, rule: Absinthe.Schema.Rule.FieldImportsExist}

    end

    it "handles circular errors" do
      defmodule Circles do
        use Absinthe.Schema.Notation

        object :foo do
          import_fields :bar
          field :name, :string
        end

        object :bar do
          import_fields :foo
          field :email, :string
        end
      end

      assert [error] = Circles.__absinthe_errors__
      assert error == %{data: %{artifact: "Field Import Cycle Error\n\nField Import in object `foo' `import_fields(:bar) forms a cycle via: (`foo' => `bar' => `foo')", value: :bar}, location: %{file: __ENV__.file, line: 63}, rule: Absinthe.Schema.Rule.NoCircularFieldImports}
    end

    it "can import fields from imported types" do
      defmodule Source do
        use Absinthe.Schema.Notation

        object :foo do
          field :name, :string
        end
      end

      defmodule Dest do
        use Absinthe.Schema.Notation

        import_types Source

        object :bar do
          import_fields :foo
        end
      end

      assert [:name] = Dest.__absinthe_type__(:bar).fields |> Map.keys
    end
  end

  describe "arg" do
    it "can be under field as an attribute" do
      assert_no_notation_error "ArgFieldValid", """
      object :foo do
        field :picture, :string do
          arg :size, :integer
        end
      end
      """
    end
    it "can be under directive as an attribute" do
      assert_no_notation_error "ArgDirectiveValid", """
      directive :test do
        arg :if, :boolean
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "ArgToplevelInvalid", """
      arg :name, :string
      """, "Invalid schema notation: `arg` must only be used within `directive`, `field`"
    end
  end

  describe "directive" do
    it "can be toplevel" do
      assert_no_notation_error "DirectiveValid", """
      directive :foo do
      end
      """
    end
    it "cannot be non-toplevel" do
      assert_notation_error "DirectiveInvalid", """
      directive :foo do
        directive :bar do
        end
      end
      """, "Invalid schema notation: `directive` must only be used toplevel"
    end
  end

  describe "enum" do
    it "can be toplevel" do
      assert_no_notation_error "EnumValid", """
      enum :foo do
      end
      """
    end
    it "cannot be non-toplevel" do
      assert_notation_error "EnumInvalid", """
      enum :foo do
        enum :bar do
        end
      end
      """, "Invalid schema notation: `enum` must only be used toplevel"
    end
  end

  describe "field" do
    it "can be under object as an attribute" do
      assert_no_notation_error "FieldObjectValid", """
      object :bar do
        field :name, :string
      end
      """
    end
    it "can be under input_object as an attribute" do
      assert_no_notation_error "FieldInputObjectValid", """
      input_object :bar do
        field :name, :string
      end
      """
    end
    it "can be under interface as an attribute" do
      assert_no_notation_error "FieldInterfaceValid", """
      interface :bar do
        field :name, :string
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "FieldToplevelInvalid", """
      field :foo, :string
      """, "Invalid schema notation: `field` must only be used within `input_object`, `interface`, `object`"
    end
  end

  describe "input_object" do
    it "can be toplevel" do
      assert_no_notation_error "InputObjectValid", """
      input_object :foo do
      end
      """
    end
    it "cannot be non-toplevel" do
      assert_notation_error "InputObjectInvalid", """
      input_object :foo do
        input_object :bar do
        end
      end
      """, "Invalid schema notation: `input_object` must only be used toplevel"
    end
  end

  describe "instruction" do
    it "can be under directive as an attribute" do
      assert_no_notation_error "InstructionValid", """
      directive :bar do
        instruction fn -> :ok end
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "InstructionToplevelInvalid", """
      instruction fn -> :ok end
      """, "Invalid schema notation: `instruction` must only be used within `directive`"
    end
    it "cannot be within object" do
      assert_notation_error "InstructionObjectInvalid", """
      object :foo do
        instruction fn -> :ok end
      end
      """, "Invalid schema notation: `instruction` must only be used within `directive`"
    end
  end

  describe "interface" do
    it "can be toplevel" do
      assert_no_notation_error "InterfaceToplevelValid", """
      interface :foo do
        field :name, :string
        resolve_type fn _, _ -> :bar end
      end
      """
    end
    it "can be under object as an attribute" do
      assert_no_notation_error "InterfaceObjectValid", """
      interface :foo do
        field :name, :string
        resolve_type fn _, _ -> :bar end
      end
      object :bar do
        interface :foo
        field :name, :string
      end
      """
    end
    it "cannot be under input_object as an attribute" do
      assert_notation_error "InterfaceInputObjectInvalid", """
      interface :foo do
        field :name, :string
        resolve_type fn _, _ -> :bar end
      end
      input_object :bar do
        interface :foo
      end
      """, "Invalid schema notation: `interface` (as an attribute) must only be used within `object`"
    end
  end

  describe "interfaces" do
    it "can be under object as an attribute" do
      assert_no_notation_error "InterfacesValid", """
      interface :bar do
        field :name, :string
        resolve_type fn _, _ -> :foo end
      end
      object :foo do
        field :name, :string
        interfaces [:bar]
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "InterfacesInvalid", """
      interface :bar do
        field :name, :string
      end
      interfaces [:bar]
      """, "Invalid schema notation: `interfaces` must only be used within `object`"
    end
  end

  describe "is_type_of" do
    it "can be under object as an attribute" do
      assert_no_notation_error "IsTypeOfValid", """
      object :bar do
        is_type_of fn _, _ -> true end
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "IsTypeOfToplevelInvalid", """
      is_type_of fn _, _ -> true end
      """, "Invalid schema notation: `is_type_of` must only be used within `object`"
    end
    it "cannot be within interface" do
      assert_notation_error "IsTypeOfInterfaceInvalid", """
      interface :foo do
        is_type_of fn _, _ -> :bar end
      end
      """, "Invalid schema notation: `is_type_of` must only be used within `object`"
    end
  end

  describe "object" do
    it "can be toplevel" do
      assert_no_notation_error "ObjectValid", """
      object :foo do
      end
      """
    end
    it "cannot be non-toplevel" do
      assert_notation_error "ObjectInvalid", """
      object :foo do
        object :bar do
        end
      end
      """, "Invalid schema notation: `object` must only be used toplevel"
    end
  end

  describe "on" do
    it "can be under directive as an attribute" do
      assert_no_notation_error "OnValid", """
      directive :foo do
        on [Foo, Bar]
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "OnInvalid", """
      on [Foo, Bar]
      """, "Invalid schema notation: `on` must only be used within `directive`"
    end
  end

  describe "parse" do
    it "can be under scalar as an attribute" do
      assert_no_notation_error "ParseValid", """
      scalar :foo do
        parse &(&1)
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "ParseInvalid", """
      parse &(&1)
      """, "Invalid schema notation: `parse` must only be used within `scalar`"
    end
  end

  describe "resolve" do
    it "can be under field as an attribute" do
      assert_no_notation_error "ResolveValid", """
      object :bar do
        field :foo, :integer do
          resolve fn _, _, _ -> {:ok, 1} end
        end
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "ResolveInvalid", """
      resolve fn _, _ -> {:ok, 1} end
      """, "Invalid schema notation: `resolve` must only be used within `field`"
    end
    it "cannot be within object" do
      assert_notation_error "ResolveInvalid2", """
      object :foo do
        resolve fn _, _ -> {:ok, 1} end
      end
      """, "Invalid schema notation: `resolve` must only be used within `field`"
    end
  end

  describe "resolve_type" do
    it "can be under interface as an attribute" do
      assert_no_notation_error "ResolveTypeValidInterface", """
      interface :bar do
        resolve_type fn _, _ -> :baz end
      end
      """
    end
    it "can be under union as an attribute" do
      assert_no_notation_error "ResolveTypeValidUnion", """
        union :bar do
          resolve_type fn _, _ -> :baz end
        end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "ResolveTypeInvalidToplevel", """
      resolve_type fn _, _ -> :bar end
      """, "Invalid schema notation: `resolve_type` must only be used within `interface`, `union`"
    end
    it "cannot be within object" do
      assert_notation_error "ResolveTypeInvalidObject", """
      object :foo do
        resolve_type fn _, _ -> :bar end
      end
      """, "Invalid schema notation: `resolve_type` must only be used within `interface`, `union`"
    end
  end

  describe "scalar" do
    it "can be toplevel" do
      assert_no_notation_error "ScalarValid", """
      scalar :foo do
      end
      """
    end
    it "cannot be non-toplevel" do
      assert_notation_error "ScalarInvalid", """
      scalar :foo do
        scalar :bar do
        end
      end
      """, "Invalid schema notation: `scalar` must only be used toplevel"
    end
  end

  describe "serialize" do
    it "can be under scalar as an attribute" do
      assert_no_notation_error "SerializeValid", """
      scalar :foo do
        serialize &(&1)
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "SerializeInvalid", """
      serialize &(&1)
      """, "Invalid schema notation: `serialize` must only be used within `scalar`"
    end
  end

  describe "types" do
    it "can be under union as an attribute" do
      assert_no_notation_error "TypesValid", """
      object :audi do
      end
      object :volvo do
      end
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

  describe "description" do
    it "can be under object as an attribute" do
      assert_no_notation_error "DescriptionValid", """
      object :item do
        description \"""
        Here's a description
        \"""
      end
      """
    end
    it "cannot be toplevel" do
      assert_notation_error "DescriptionInvalid", ~s(description "test"), "Invalid schema notation: `description` must not be used toplevel"
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
    assert_raise(Absinthe.Schema.Notation.Error, message, fn ->
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
    assert """
    defmodule MyTestSchema.#{name} do
      use Absinthe.Schema
      #{text}
    end
    """
    |> Code.eval_string
  end

end
