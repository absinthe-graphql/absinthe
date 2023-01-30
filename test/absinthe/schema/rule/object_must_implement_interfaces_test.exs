defmodule Absinthe.Schema.Rule.ObjectMustImplementInterfacesTest do
  use Absinthe.Case, async: true

  defmodule Types do
    use Absinthe.Schema.Notation

    object :user do
      interface :named
      interface :favorite_foods
      interface :parented
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

      resolve_type fn
        %{type: :dog}, _ -> :dog
        %{type: :user}, _ -> :user
        %{type: :cat}, _ -> :cat
        _, _ -> nil
      end
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
      interface :parented
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
      interface :parented
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

  test "interfaces are propagated across type imports" do
    assert %{
             named: [:cat, :dog, :user],
             favorite_foods: [:cat, :dog, :user],
             parented: [:cat, :dog, :user]
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

    type Image implements Resource & Node {
      id: ID!
      url: String
      thumbnail: String
    }

    """

    def hydrate(%Absinthe.Blueprint.Schema.InterfaceTypeDefinition{}, _) do
      {:resolve_type, &__MODULE__.resolve_type/1}
    end

    def hydrate(_node, _ancestors), do: []

    def resolve_type(_), do: false

    query do
    end
  end

  test "interfaces are set from sdl" do
    assert %{
             node: [:image],
             resource: [:image]
           } ==
             InterfaceImplementsInterfaces.__absinthe_interface_implementors__()
  end

  defmodule InterfaceFieldsReferenceInterfaces do
    use Absinthe.Schema

    import_sdl """
    interface Pet {
      food: PetFood!
    }

    interface PetFood {
      brand: String!
    }

    type Dog implements Pet {
      food: DogFood!
    }

    type DogFood implements PetFood {
      brand: String!
    }

    type Cat implements Pet {
      food: CatFood!
    }

    type CatFood implements PetFood {
      brand: String!
    }
    """

    query do
    end

    def hydrate(%{identifier: :pet}, _) do
      [{:resolve_type, &__MODULE__.pet/2}]
    end

    def hydrate(%{identifier: :pet_food}, _) do
      [{:resolve_type, &__MODULE__.pet_food/2}]
    end

    def hydrate(_, _), do: []

    def pet(_, _), do: nil
    def pet_food(_, _), do: nil
  end

  test "interface fields can reference other interfaces" do
    assert %{
             pet: [:cat, :dog],
             pet_food: [:cat_food, :dog_food]
           } ==
             InterfaceFieldsReferenceInterfaces.__absinthe_interface_implementors__()
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
