defmodule Absinthe.Schema.Rule.ObjectMustImplementInterfacesTest do
  use Absinthe.Case, async: true

  defmodule Types do
    use Absinthe.Schema.Notation

    object :user do
      interface :named
      interface :favorite_foods
      field :name, :string
      field :id, :id
      field :parent, :named
      field :another_parent, :user
      field :color, non_null(list_of(non_null(:string)))
    end
  end

  defmodule Schema do
    use Absinthe.Schema
    import_types Types

    interface :parented do
      field :parent, :named
      field :another_parent, :named
    end

    interface :named do
      interface :parented
      field :name, :string
      field :parent, :named
      field :another_parent, :named

      resolve_type fn
        %{type: :dog}, _ -> :dog
        %{type: :user}, _ -> :user
        %{type: :cat}, _ -> :cat
        _, _ -> nil
      end
    end

    interface :favorite_foods do
      field :color, list_of(:string)

      resolve_type fn
        %{type: :dog}, _ -> :dog
        %{type: :user}, _ -> :user
        %{type: :cat}, _ -> :cat
        _, _ -> nil
      end
    end

    object :dog do
      field :name, :string
      interface :named
      interface :favorite_foods
      field :parent, :named
      field :another_parent, :user
      field :color, list_of(non_null(:string))
    end

    # An object field type is a valid sub-type if it is a Non-Null variant of a
    # valid sub-type of the interface field type.
    object :cat do
      interface :named
      interface :favorite_foods
      field :name, non_null(:string)
      field :parent, :named
      field :another_parent, :user
      field :color, non_null(list_of(:string))
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
    assert %{
             named: [:cat, :dog, :user],
             favorite_foods: [:cat, :dog, :user],
             parented: [:named]
           } ==
             Schema.__absinthe_interface_implementors__()
  end

  defmodule InterfaceImplementsInterfaces do
    use Absinthe.Schema

    import_sdl """
    interface Node {
      id: ID!
    }

    interface Resource implements Node {
      id: ID!
      url: String
    }

    interface Image implements Resource & Node {
      id: ID!
      url: String
      thumbnail: String
    }

    """

    query do
    end
  end

  test "interfaces are set from sdl" do
    assert %{
             image: [],
             node: [:image, :resource],
             resource: [:image]
           } ==
             InterfaceImplementsInterfaces.__absinthe_interface_implementors__()
  end

  test "is enforced" do
    assert_schema_error("invalid_interface_types", [
      %{
        extra: %{
          fields: [:name],
          object: :foo,
          interface: :named
        },
        locations: [
          %{
            file: "test/support/fixtures/dynamic/invalid_interface_types.exs",
            line: 13
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
