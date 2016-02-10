defmodule Absinthe.Type.DirectiveTest do
  use ExSpec, async: true

  alias Absinthe.Schema

  defmodule TestSchema do
    use Absinthe.Schema

    query [
      fields: [
        nonce: [type: :string]
      ]
    ]

  end

  describe "directives" do
    it "are loaded as built-ins" do
      assert %{skip: "skip", include: "include"} = TestSchema.__absinthe_directives__
      assert TestSchema.__absinthe_directive__(:skip)
      assert TestSchema.__absinthe_directive__("skip") == TestSchema.__absinthe_directive__(:skip)
      assert Schema.lookup_directive(TestSchema, :skip) == TestSchema.__absinthe_directive__(:skip)
      assert Schema.lookup_directive(TestSchema, "skip") == TestSchema.__absinthe_directive__(:skip)
    end

  end

  describe "the `@skip` directive" do
    @query_field """
    query Test($skipPerson: Boolean) {
      person @skip(if: $skipPerson) {
        name
      }
    }
    """
    @query_fragment """
    query Test($skipAge: Boolean) {
      person {
        name
        ...Aging @skip(if: $skipAge)
      }
    }
    fragment Aging on Person {
      age
    }
    """
    it "is defined" do
      assert Schema.lookup_directive(ContactSchema, :skip)
    end
    it "behaves as expected for a field" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == Absinthe.run(@query_field, ContactSchema, variables: %{"skipPerson" => false})
      assert {:ok, %{data: %{}}} == Absinthe.run(@query_field, ContactSchema, variables: %{"skipPerson" => true})
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == Absinthe.run(@query_field, ContactSchema)
    end
    @tag :frag
    it "behaves as expected for a fragment" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query_fragment, ContactSchema, variables: %{"skipAge" => false})
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == Absinthe.run(@query_fragment, ContactSchema, variables: %{"skipAge" => true})
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query_fragment, ContactSchema)
    end
  end

  describe "the `@include` directive" do
    @query_field """
    query Test($includePerson: Boolean) {
      person @include(if: $includePerson) {
        name
      }
    }
    """
    @query_fragment """
    query Test($includeAge: Boolean) {
      person {
        name
        ...Aging @include(if: $includeAge)
      }
    }
    fragment Aging on Person {
      age
    }
    """
    it "is defined" do
      assert Schema.lookup_directive(ContactSchema, :include)
    end
    it "behaves as expected for a field" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == Absinthe.run(@query_field, ContactSchema, variables: %{"includePerson" => true})
      assert {:ok, %{data: %{}}} == Absinthe.run(@query_field, ContactSchema, variables: %{"includePerson" => false})
      assert {:ok, %{data: %{}}} == Absinthe.run(@query_field, ContactSchema)
    end
    it "behaves as expected for a fragment" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query_fragment, ContactSchema, variables: %{"includeAge" => true})
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == Absinthe.run(@query_fragment, ContactSchema, variables: %{"includeAge" => false})
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == Absinthe.run(@query_fragment, ContactSchema)
    end
  end

  describe "for inline fragments without type conditions" do

    @query """
    query Q($skipAge: Boolean = false) {
      person {
        name
        ... @skip(if: $skipAge) {
          age
        }
      }
    }
    """

    it "works as expected" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == Absinthe.run(@query, ContactSchema, variables: %{"skipAge" => true})
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query, ContactSchema, variables: %{"skipAge" => false})
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query, ContactSchema)
    end

  end

  describe "for inline fragments with type conditions" do

    @query """
    query Q($skipAge: Boolean = false) {
      person {
        name
        ... on Person @skip(if: $skipAge) {
          age
        }
      }
    }
    """

    it "works as expected" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} == Absinthe.run(@query, ContactSchema, variables: %{"skipAge" => true})
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query, ContactSchema, variables: %{"skipAge" => false})
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query, ContactSchema)
    end

  end

end
