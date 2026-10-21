defmodule Absinthe.ResolutionTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    interface :named do
      field :name, :string

      resolve_type fn _, _ -> :user end
    end

    object :user do
      interface :named
      field :id, :id
      field :name, :string
    end

    query do
      field :user, :user do
        resolve fn _, info ->
          fields = Absinthe.Resolution.project(info) |> Enum.map(& &1.name)

          # ghetto escape hatch
          send(self(), {:fields, fields})
          {:ok, nil}
        end
      end

      field :invalid_resolver, :string do
        resolve("bogus")
      end

      field :map_resolver, :string do
        resolve fn _, _ ->
          {:error, %{message: "map"}}
        end
      end

      field :struct_resolver, :string do
        resolve fn _, _ ->
          # we are using the Date struct here, but it can be any struct
          # with an implementation for String.Chars
          {:error, ~D[2025-01-01]}
        end
      end

      field :abstract_resolver, :named do
        resolve fn _, info ->
          Absinthe.Resolution.project(info)
          {:ok, nil}
        end
      end

      field :non_null_abstract_resolver, non_null(:named) do
        resolve fn _, info ->
          Absinthe.Resolution.project(info)
          {:ok, nil}
        end
      end

      field :list_abstract_resolver, list_of(:named) do
        resolve fn _, info ->
          Absinthe.Resolution.project(info)
          {:ok, nil}
        end
      end

      field :abstract_resolver_with_type, :named do
        resolve fn _, info ->
          fields = Absinthe.Resolution.project(info, :user) |> Enum.map(& &1.name)

          send(self(), {:fields, fields})
          {:ok, nil}
        end
      end
    end
  end

  test "project/1 works" do
    doc = """
    { user { id, name } }
    """

    {:ok, _} = Absinthe.run(doc, Schema)

    assert_receive({:fields, fields})

    assert ["id", "name"] == fields
  end

  test "project/1 works with fragments and things" do
    doc = """
    {
      user {
        ... on User {
          id
        }
        ... on Named {
          name
        }
      }
    }
    """

    {:ok, _} = Absinthe.run(doc, Schema)

    assert_receive({:fields, fields})

    assert ["id", "name"] == fields
  end

  test "project/1 raises on an abstract type" do
    doc = """
    { abstractResolver { name ... on User { id } } }
    """

    assert_raise RuntimeError, ~r/Use `project\/2` instead of `project\/1`/, fn ->
      Absinthe.run(doc, Schema)
    end
  end

  test "project/1 raises on a non null abstract type" do
    doc = """
    { nonNullAbstractResolver { name ... on User { id } } }
    """

    assert_raise RuntimeError, ~r/Use `project\/2` instead of `project\/1`/, fn ->
      Absinthe.run(doc, Schema)
    end
  end

  test "project/1 raises on a list of an abstract type" do
    doc = """
    { listAbstractResolver { name ... on User { id } } }
    """

    assert_raise RuntimeError, ~r/Use `project\/2` instead of `project\/1`/, fn ->
      Absinthe.run(doc, Schema)
    end
  end

  test "project/2 works on an abstract type" do
    doc = """
    { abstractResolverWithType { name ... on User { id } } }
    """

    {:ok, _} = Absinthe.run(doc, Schema)

    assert_receive({:fields, fields})

    assert ["name", "id"] == fields
  end

  test "invalid resolver" do
    doc = """
    { invalidResolver }
    """

    assert_raise Absinthe.ExecutionError,
                 ~r/Field resolve property must be a 2 arity anonymous function, 3 arity\nanonymous function, or a `{Module, :function}` tuple.\n\nInstead got: \"bogus\"\n\nResolving field:\n\n    invalidResolver/,
                 fn ->
                   {:ok, _} = Absinthe.run(doc, Schema)
                 end
  end

  test "resolves error with map value" do
    doc = """
    { mapResolver }
    """

    assert {:ok,
            %{
              data: %{"mapResolver" => nil},
              errors: [%{message: "map"}]
            }} = Absinthe.run(doc, Schema)
  end

  test "resolves error with struct value implementing String.Chars" do
    doc = """
    { structResolver }
    """

    assert {:ok,
            %{
              data: %{"structResolver" => nil},
              errors: [%{message: "2025-01-01"}]
            }} = Absinthe.run(doc, Schema)
  end
end
