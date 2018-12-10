defmodule Absinthe.Schema.Notation.ImportTest do
  use ExUnit.Case, async: true

  defp field_list(module, name) do
    module.__absinthe_type__(name).fields
    |> Enum.filter(&(!introspection?(&1)))
    |> Keyword.keys()
    |> Enum.sort()
  end

  defp introspection?({_, field}) do
    Absinthe.Type.introspection?(field)
  end

  describe "import fields" do
    test "fields can be imported" do
      defmodule Foo do
        use Absinthe.Schema

        query do
          # Query type must exist
        end

        object :foo do
          field :name, :string
        end

        object :bar do
          import_fields :foo
          field :email, :string
        end
      end

      assert [:email, :name] = field_list(Foo, :bar)
    end

    test "works for input objects" do
      defmodule InputFoo do
        use Absinthe.Schema

        query do
          # Query type must exist
        end

        input_object :foo do
          field :name, :string
        end

        input_object :bar do
          import_fields :foo
          field :email, :string
        end
      end

      fields = InputFoo.__absinthe_type__(:bar).fields

      assert [:email, :name] = fields |> Map.keys() |> Enum.sort()
    end

    test "works for interfaces" do
      defmodule InterfaceFoo do
        use Absinthe.Schema

        query do
          # Query type must exist
        end

        object :cool_fields do
          field :name, :string
        end

        interface :foo do
          import_fields :cool_fields
          resolve_type fn _, _ -> :real_foo end
        end

        object :real_foo do
          interface :foo
          import_fields :cool_fields
        end
      end

      assert [:name] = field_list(InterfaceFoo, :foo)

      assert [:name] = field_list(InterfaceFoo, :real_foo)
    end

    test "can work transitively" do
      defmodule Bar do
        use Absinthe.Schema

        query do
          # Query type must exist
        end

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

      assert [:age, :email, :name] == field_list(Bar, :baz)
    end

    @tag :pending_schema
    test "raises errors nicely" do
      defmodule ErrorSchema do
        use Absinthe.Schema.Notation

        object :bar do
          import_fields :asdf
          field :email, :string
        end
      end

      assert [error] = ErrorSchema.__absinthe_errors__()

      assert %{
               data: %{
                 artifact:
                   "Field Import Error\n\nObject :bar imports fields from :asdf but\n:asdf does not exist in the schema!",
                 value: :asdf
               },
               location: %{file: _, line: _},
               rule: Absinthe.Schema.Rule.FieldImportsExist
             } = error
    end

    @tag :pending_schema
    test "handles circular errors" do
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

      assert [error] = Circles.__absinthe_errors__()

      assert %{
               data: %{
                 artifact:
                   "Field Import Cycle Error\n\nField Import in object `foo' `import_fields(:bar) forms a cycle via: (`foo' => `bar' => `foo')",
                 value: :bar
               },
               location: %{file: _, line: _},
               rule: Absinthe.Schema.Rule.NoCircularFieldImports
             } = error
    end

    test "can import types from more than one thing" do
      defmodule Multiples do
        use Absinthe.Schema

        object :foo do
          field :name, :string
        end

        object :bar do
          field :email, :string
        end

        query do
          import_fields :foo
          import_fields :bar
          field :age, :integer
        end
      end

      assert [:age, :email, :name] == field_list(Multiples, :query)
    end

    test "can import fields from imported types" do
      defmodule Source1 do
        use Absinthe.Schema

        query do
          # Query type must exist
        end

        object :foo do
          field :name, :string
        end
      end

      defmodule Source2 do
        use Absinthe.Schema

        query do
          # Query type must exist
        end

        object :bar do
          field :email, :string
        end
      end

      defmodule Dest do
        use Absinthe.Schema

        query do
          # Query type must exist
        end

        import_types Source1
        import_types Source2

        object :baz do
          import_fields :foo
          import_fields :bar
        end
      end

      assert [:email, :name] = field_list(Dest, :baz)
    end
  end
end
