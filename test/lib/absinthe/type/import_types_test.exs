defmodule Absinthe.Type.ImportTypesTest do
  use Absinthe.Case, async: true

  alias Absinthe.Test.ImportTypes

  context "import_types" do

    it "works with a plain atom" do
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :receipt)
    end

    it "works with {}" do
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :customer)
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :employee)
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :order)
    end

    it "works with an alias and plain atom" do
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :weekly_schedule)
    end

    it "works with an alias and {}" do
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :mailing_address)
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :contact_method)
      assert Absinthe.Schema.lookup_type(ImportTypes.Schema, :contact_kind)
    end

  end

end
