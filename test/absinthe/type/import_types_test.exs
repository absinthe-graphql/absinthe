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

  defmodule TestSchema do
    use Absinthe.Schema
    @module_attribute "module_attribute"

    query do
      field :module_attribute, :string, description: @module_attribute
    end
  end

  # From inside `defp expand_ast` in `Absinthe.Schema.Notation`:
  #
  # > We don't want to expand `@bla` into Module.get_attribute(module, @bla) because this will
  # > fail at runtime. Remember that the ast gets put into a generated `__absinthe_blueprint__`
  # > function which is called at "__after_compile__" time, but may be called at runtime
  # > depending on the ordering of how modules get compiled.
  #
  # This test checks that __absinthe_blueprint__ runs and doesn't raise an error saying
  # "Module.get_attribute" cannot be called because the module is already compiled". This error
  # happens because the `@module_attribute` gets expanded by `expand_ast` into
  # `Module.get_attribute(Absinthe.Type.QueryTest.TestSchema, :module_attribute, <line_number>)`.
  #
  # We ensure __absinthe_blueprint__ is runnable at runtime because in projects where the schema
  # is split into multiple modules, one of the modules may already have completely finished
  # compiling, dumping the Module attribute data (they are baked in to the code at compile time)
  # which means that the `Module.get_attribute` call will raise the error mentioned above
  #
  test "__absinthe_blueprint__ is callable at runtime even if there is a module attribute" do
    # Sanity check
    {:module, TestSchema} = Code.ensure_compiled(TestSchema)
    assert match? %Absinthe.Blueprint{}, TestSchema.__absinthe_blueprint__()
  end
end
