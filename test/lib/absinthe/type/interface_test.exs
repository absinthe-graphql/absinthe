defmodule Absinthe.Type.InterfaceTest do
  use Absinthe.Case, async: true
  import AssertResult
  use SupportSchemas

  alias Absinthe.Schema.Rule
  alias Absinthe.Schema

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      field :foo, type: :foo
      field :bar, type: :bar
      field :named_thing, :named do
        resolve fn _, _ ->
          {:ok, %{}}
        end
      end
    end

    object :foo do
      field :name, :string
      is_type_of fn
        _ ->
          true
      end
      interface :named
    end

    object :bar do
      field :name, :string
      is_type_of fn
        _ ->
          true
      end
      interface :named
    end

    # NOT USED IN THE QUERY
    object :baz do
      field :name, :string
      is_type_of fn
        _ ->
          true
      end
      interfaces [:named]
    end

    interface :named do
      description "An interface"
      field :name, :string
      resolve_type fn
        _, _ ->
          nil # just a value
      end
    end

  end

  context "interface" do

    it "can be defined" do
      obj = TestSchema.__absinthe_type__(:named)
      assert %Absinthe.Type.Interface{name: "Named", description: "An interface"} = obj
      assert obj.resolve_type
    end

    it "captures the relationships in the schema" do
      implementors = Map.get(TestSchema.__absinthe_interface_implementors__, :named, [])
      assert :foo in implementors
      assert :bar in implementors
      # Not directly in squery, but because it's
      # an available type and there's a field that
      # defines the interface as a type
      assert :baz in implementors
    end

    it "can find implementors" do
      obj = TestSchema.__absinthe_type__(:named)
      assert length(Schema.implementors(TestSchema, obj)) == 3
    end

  end

  context "an object that implements an interface" do

    context "with the interface as a field type" do

      it "can select fields that are declared by the interface" do
        result = """
        { contact { entity { name } } }
        """ |> Absinthe.run(ContactSchema)
        assert_result {:ok, %{data: %{"contact" => %{"entity" => %{"name" => "Bruce"}}}}}, result
      end
    it "can't select fields from an implementing type without 'on'" do
        result = """
        { contact { entity { name age } } }
        """ |> Absinthe.run(ContactSchema)
        assert_result {:ok, %{errors: [%{message: ~s(Cannot query field "age" on type "NamedEntity". Did you mean to use an inline fragment on "Person"?)}]}}, result
      end

      it "can select fields from an implementing type with 'on'" do
        result = """
        { contact { entity { name ... on Person { age } } } }
        """ |> Absinthe.run(ContactSchema)
        assert_result {:ok, %{data: %{"contact" => %{"entity" => %{"name" => "Bruce", "age" => 35}}}}}, result
      end

    end

  end

  context "when it doesn't define those fields" do

    it "reports schema errors" do
      assert_schema_error(
        "bad_interface_schema",
        [
          %{rule: Rule.ObjectMustImplementInterfaces, data: %{object: "Foo", interface: "Aged"}},
          %{rule: Rule.ObjectMustImplementInterfaces, data: %{object: "Foo", interface: "Named"}},
          %{rule: Rule.ObjectInterfacesMustBeValid, data: %{object: "Quux", interface: "Foo"}},
          %{rule: Rule.InterfacesMustResolveTypes, data: "Named"},
        ]
      )
    end
  end

  it "can query simple InterfaceSubtypeSchema" do
    result = """
    {
      box {
        item {
          name
          cost
        }
      }
    }
    """
    |> run(Absinthe.InterfaceSubtypeSchema)
    assert_result {:ok, %{data: %{"box" => %{"item" => %{"name" => "Computer", "cost" => 1000}}}}}, result
  end

  it "can query InterfaceSubtypeSchema treating box as HasItem" do
    result = """
    {
      box {
        ... on HasItem {
          item {
            name
          }
        }
      }
    }
    """
    |> run(Absinthe.InterfaceSubtypeSchema)
    assert_result {:ok, %{data: %{"box" => %{"item" => %{"name" => "Computer"}}}}}, result
  end

  it "can query InterfaceSubtypeSchema treating box as HasItem and item as ValuedItem" do
    result = """
    {
      box {
        ... on HasItem {
          item {
            name
            ... on ValuedItem {
              cost
            }
          }
        }
      }
    }
    """
    |> run(Absinthe.InterfaceSubtypeSchema)
    assert_result {:ok, %{data: %{"box" => %{"item" => %{"name" => "Computer", "cost" => 1000}}}}}, result
  end

  it "rejects querying InterfaceSubtypeSchema treating box as HasItem asking for cost" do
    result = """
    {
      box {
        ... on HasItem {
          item {
            name
            cost
          }
        }
      }
    }
    """
    |> run(Absinthe.InterfaceSubtypeSchema)
    assert_result {:ok, %{errors: [%{message: "Cannot query field \"cost\" on type \"Item\". Did you mean to use an inline fragment on \"ValuedItem\"?"}]}}, result
  end

  it "works even when resolve_type returns nil" do
    result = """
    {
      namedThing {
        name
      }
    }
    """
    |> run(TestSchema)
    assert_result {:ok, %{data: %{"namedThing" => %{}}}}, result
  end
end
