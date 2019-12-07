defmodule Absinthe.Schema.Rule.ObjectMustImplementInterfacesTest do
  use Absinthe.Case, async: true

  defmodule Types do
    use Absinthe.Schema.Notation

    object :user do
      interface :named
      field :name, :string
      field :id, :id
      field :parent, :named
      field :another_parent, :user
    end
  end

  defmodule Schema do
    use Absinthe.Schema
    import_types Types

    interface :named do
      field :name, :string
      field :parent, :named
      field :another_parent, :named

      resolve_type fn
        %{type: :dog}, _ -> :dog
        %{type: :user}, _ -> :user
        _, _ -> nil
      end
    end

    object :dog do
      field :name, :string
      interface :named
      field :parent, :named
      field :another_parent, :user
    end

    query do
      field :user, :user do
        resolve fn _, _ ->
          {:ok,
           %{
             type: :user,
             id: "abc-123",
             name: "User Name",
             parent: %{type: :user, id: "def-456", name: "Parent User"},
             another_parent: %{type: :user, id: "ghi-789", name: "Another Parent"}
           }}
        end
      end
    end
  end

  test "interfaces are propogated across type imports" do
    assert %{named: [:dog, :user]} == Schema.__absinthe_interface_implementors__()
  end

  test "is enforced" do
    assert_schema_error("invalid_interface_types", [
      %{
        extra: %{
          fields: [:name],
          object: :user,
          interface: :named
        },
        locations: [
          %{
            file: "test/support/fixtures/dynamic/invalid_interface_types.exs",
            line: 4
          }
        ],
        phase: Absinthe.Phase.Schema.Validation.ObjectMustImplementInterfaces
      }
    ])
  end

  test "Interfaces can contain fields of their own type" do
    doc = """
    {
      user {
        ... on User {
          id
          parent {
            ... on Named {
              name
            }
            ... on User {
              id
            }
          }
          anotherParent {
            id
          }
        }
        ... on Named {
          name
        }
      }
    }
    """

    {:ok, %{data: data}} = Absinthe.run(doc, Schema)

    assert get_in(data, ["user", "id"]) == "abc-123"
    assert get_in(data, ["user", "parent", "id"]) == "def-456"
    assert get_in(data, ["user", "parent", "name"]) == "Parent User"
    assert get_in(data, ["user", "anotherParent", "id"]) == "ghi-789"
  end
end
