defmodule Absinthe.Type.OrderedDirectiveTest do
  use Absinthe.Case, async: false, ordered: true
  use OrdMap

  alias Absinthe.Schema
  import AssertResult

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      field :nonce, :string
    end

  end

  context "directives" do
    it "are loaded as built-ins" do
      assert %{skip: "skip", include: "include"} = TestSchema.__absinthe_directives__
      assert TestSchema.__absinthe_directive__(:skip)
      assert TestSchema.__absinthe_directive__("skip") == TestSchema.__absinthe_directive__(:skip)
      assert Schema.lookup_directive(TestSchema, :skip) == TestSchema.__absinthe_directive__(:skip)
      assert Schema.lookup_directive(TestSchema, "skip") == TestSchema.__absinthe_directive__(:skip)
    end

  end

  context "the `@skip` directive" do
    @query_field """
    query Test($skipPerson: Boolean) {
      person @skip(if: $skipPerson) {
        name
      }
    }
    """
    it "is defined" do
      assert Schema.lookup_directive(ContactSchema, :skip)
    end
    it "behaves as expected for a field" do
      assert {:ok, %{data: o%{"person" => o%{"name" => "Bruce"}}}} == Absinthe.run(@query_field, ContactSchema, variables: %{"skipPerson" => false})
      assert {:ok, %{data: o%{}}} == Absinthe.run(@query_field, ContactSchema, variables: %{"skipPerson" => true})
      assert_result {:ok, %{errors: [%{message: ~s(In argument "if": Expected type "Boolean!", found null.)}]}}, run(@query_field, ContactSchema)
    end

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
    it "behaves as expected for a fragment" do
      assert_result {:ok, %{data: o%{"person" => o%{"name" => "Bruce", "age" => 35}}}}, run(@query_fragment, ContactSchema, variables: %{"skipAge" => false})
      assert_result {:ok, %{data: o%{"person" => o%{"name" => "Bruce"}}}}, run(@query_fragment, ContactSchema, variables: %{"skipAge" => true})
      assert_result {:ok, %{errors: [%{message: ~s(In argument "if": Expected type "Boolean!", found null.)}]}}, run(@query_fragment, ContactSchema)
    end
  end

  context "the `@include` directive" do
    @query_field """
    query Test($includePerson: Boolean) {
      person @include(if: $includePerson) {
        name
      }
    }
    """
    it "is defined" do
      assert Schema.lookup_directive(ContactSchema, :include)
    end
    it "behaves as expected for a field" do
      assert_result {:ok, %{data: o%{"person" => o%{"name" => "Bruce"}}}}, run(@query_field, ContactSchema, variables: %{"includePerson" => true})
      assert_result {:ok, %{data: o%{}}}, run(@query_field, ContactSchema, variables: %{"includePerson" => false})
      assert_result {:ok, %{errors: [%{locations: [%{column: 0, line: 2}], message: ~s(In argument "if": Expected type "Boolean!", found null.)}]}}, run(@query_field, ContactSchema)
    end

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
    it "behaves as expected for a fragment" do
      assert {:ok, %{data: o%{"person" => o%{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query_fragment, ContactSchema, variables: %{"includeAge" => true})
      assert {:ok, %{data: o%{"person" => o%{"name" => "Bruce"}}}} == Absinthe.run(@query_fragment, ContactSchema, variables: %{"includeAge" => false})
    end

    it "should return an error if the variable is not supplied" do
      assert {:ok, %{errors: errors}} = Absinthe.run(@query_fragment, ContactSchema)
      assert [] != errors
    end
  end

  context "for inline fragments without type conditions" do

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
      assert {:ok, %{data: o%{"person" => o%{"name" => "Bruce"}}}} == Absinthe.run(@query, ContactSchema, variables: %{"skipAge" => true})
      assert {:ok, %{data: o%{"person" => o%{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query, ContactSchema, variables: %{"skipAge" => false})
      assert {:ok, %{data: o%{"person" => o%{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query, ContactSchema)
    end

  end

  context "for inline fragments with type conditions" do

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
      assert {:ok, %{data: o%{"person" => o%{"name" => "Bruce"}}}} == Absinthe.run(@query, ContactSchema, variables: %{"skipAge" => true})
      assert {:ok, %{data: o%{"person" => o%{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query, ContactSchema, variables: %{"skipAge" => false})
      assert {:ok, %{data: o%{"person" => o%{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query, ContactSchema)
    end

  end

end
