defmodule Absinthe.Schema.Notation.ImportTest do
  use ExUnit.Case, async: true

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

      assert [:email, :name] = Foo.__absinthe_type__(:bar).fields |> Map.keys() |> Enum.sort()
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

      interface_fields = InterfaceFoo.__absinthe_type__(:foo).fields
      assert [:name] = interface_fields |> Map.keys() |> Enum.sort()

      object_fields = InterfaceFoo.__absinthe_type__(:real_foo).fields
      assert [:name] = object_fields |> Map.keys() |> Enum.sort()
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

      assert [:age, :email, :name] ==
               Bar.__absinthe_type__(:baz).fields |> Map.keys() |> Enum.sort()
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

      assert [:age, :email, :name] ==
               Multiples.__absinthe_type__(:query).fields |> Map.keys() |> Enum.sort()
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

      assert [:email, :name] = Dest.__absinthe_type__(:baz).fields |> Map.keys() |> Enum.sort()
    end
  end
end
