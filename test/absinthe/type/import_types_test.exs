defmodule Absinthe.Type.ImportTypesTest do
  use Absinthe.Case, async: true

  alias Absinthe.Fixtures.ImportTypes

  describe "import_types" do
    test "works with a plain atom" do
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :receipt)
    end

    test "works with {}" do
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :customer)
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :employee)
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :order)
    end

    test "works with an alias and plain atom" do
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :weekly_schedule)
    end

    test "works with an alias and {}" do
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :mailing_address)
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :contact_method)
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :contact_kind)
    end

    test "works with an alias, {} and scoped reference" do
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :avatar)
    end

    test "works with __MODULE__ and {}" do
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :flag)
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :value_type_enum)

      assert Absinthe.Schema.lookup_type(ImportTypes.SelfContainedSchema, :decline_reasons)
      assert Absinthe.Schema.lookup_type(ImportTypes.SelfContainedSchema, :credit_card)
      assert Absinthe.Schema.lookup_type(ImportTypes.SelfContainedSchema, :credit_card_type)
      assert Absinthe.Schema.lookup_type(ImportTypes.SelfContainedSchema, :category)
      assert Absinthe.Schema.lookup_type(ImportTypes.SelfContainedSchema, :role_enum)
    end
  end
end
