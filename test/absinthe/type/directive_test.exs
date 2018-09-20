defmodule Absinthe.Type.DirectiveTest do
  use Absinthe.Case, async: true

  alias Absinthe.Schema

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      field :nonce, :string
    end
  end

  describe "directives" do
    test "are loaded as built-ins" do
      assert %{skip: "skip", include: "include"} = TestSchema.__absinthe_directives__()
      assert TestSchema.__absinthe_directive__(:skip)
      assert TestSchema.__absinthe_directive__("skip") == TestSchema.__absinthe_directive__(:skip)

      assert Schema.lookup_directive(TestSchema, :skip) ==
               TestSchema.__absinthe_directive__(:skip)

      assert Schema.lookup_directive(TestSchema, "skip") ==
               TestSchema.__absinthe_directive__(:skip)
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
    test "is defined" do
      assert Schema.lookup_directive(Absinthe.Fixtures.ContactSchema, :skip)
    end

    test "behaves as expected for a field" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} ==
               Absinthe.run(
                 @query_field,
                 Absinthe.Fixtures.ContactSchema,
                 variables: %{"skipPerson" => false}
               )

      assert {:ok, %{data: %{}}} ==
               Absinthe.run(
                 @query_field,
                 Absinthe.Fixtures.ContactSchema,
                 variables: %{"skipPerson" => true}
               )

      assert_result(
        {:ok,
         %{errors: [%{message: ~s(In argument "if": Expected type "Boolean!", found null.)}]}},
        run(@query_field, Absinthe.Fixtures.ContactSchema)
      )
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
    test "behaves as expected for a fragment" do
      assert_result(
        {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}},
        run(@query_fragment, Absinthe.Fixtures.ContactSchema, variables: %{"skipAge" => false})
      )

      assert_result(
        {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}},
        run(@query_fragment, Absinthe.Fixtures.ContactSchema, variables: %{"skipAge" => true})
      )

      assert_result(
        {:ok,
         %{errors: [%{message: ~s(In argument "if": Expected type "Boolean!", found null.)}]}},
        run(@query_fragment, Absinthe.Fixtures.ContactSchema)
      )
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
    test "is defined" do
      assert Schema.lookup_directive(Absinthe.Fixtures.ContactSchema, :include)
    end

    test "behaves as expected for a field" do
      assert_result(
        {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}},
        run(@query_field, Absinthe.Fixtures.ContactSchema, variables: %{"includePerson" => true})
      )

      assert_result(
        {:ok, %{data: %{}}},
        run(@query_field, Absinthe.Fixtures.ContactSchema, variables: %{"includePerson" => false})
      )

      assert_result(
        {:ok,
         %{
           errors: [
             %{
               locations: [%{column: 19, line: 2}],
               message: ~s(In argument "if": Expected type "Boolean!", found null.)
             }
           ]
         }},
        run(@query_field, Absinthe.Fixtures.ContactSchema)
      )
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
    test "behaves as expected for a fragment" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} ==
               Absinthe.run(
                 @query_fragment,
                 Absinthe.Fixtures.ContactSchema,
                 variables: %{"includeAge" => true}
               )

      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} ==
               Absinthe.run(
                 @query_fragment,
                 Absinthe.Fixtures.ContactSchema,
                 variables: %{"includeAge" => false}
               )
    end

    test "should return an error if the variable is not supplied" do
      assert {:ok, %{errors: errors}} =
               Absinthe.run(@query_fragment, Absinthe.Fixtures.ContactSchema)

      assert [] != errors
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

    test "works as expected" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} ==
               Absinthe.run(
                 @query,
                 Absinthe.Fixtures.ContactSchema,
                 variables: %{"skipAge" => true}
               )

      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} ==
               Absinthe.run(
                 @query,
                 Absinthe.Fixtures.ContactSchema,
                 variables: %{"skipAge" => false}
               )

      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} ==
               Absinthe.run(@query, Absinthe.Fixtures.ContactSchema)
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

    test "works as expected" do
      assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} ==
               Absinthe.run(
                 @query,
                 Absinthe.Fixtures.ContactSchema,
                 variables: %{"skipAge" => true}
               )

      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} ==
               Absinthe.run(
                 @query,
                 Absinthe.Fixtures.ContactSchema,
                 variables: %{"skipAge" => false}
               )

      assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} ==
               Absinthe.run(@query, Absinthe.Fixtures.ContactSchema)
    end
  end
end
