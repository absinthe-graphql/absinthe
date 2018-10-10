defmodule Absinthe.Schema.Rule.ObjectMustImplementInterfacesTest do
  use Absinthe.Case, async: true

  defmodule Types do
    use Absinthe.Schema.Notation

    object :user do
      interface :named
      field :name, :string
    end
  end

  defmodule Schema do
    use Absinthe.Schema
    import_types Types

    interface :named do
      field :name, :string

      resolve_type fn
        %{type: :dog} -> :dog
        %{type: :user} -> :user
        _ -> nil
      end
    end

    object :dog do
      field :name, :string
      interface :named
    end

    query do
    end
  end

  test "interfaces are propogated across type imports" do
    assert %{named: [:dog, :user]} == Schema.__absinthe_interface_implementors__()
  end

  test "is enforced" do
    assert_schema_error("invalid_interface_types", [
      %{
        data: %{
          fields: [:name],
          object: "User",
          interface: "Named",
        },
        location: %{
          file: "/Users/ben/src/absinthe/test/support/fixtures/dynamic/invalid_interface_types.exs",
          line: 10
        },
        rule: Absinthe.Schema.Rule.ObjectMustImplementInterfaces
      }
    ])
  end
end
