defmodule Absinthe.Execution.DeprecationTest do
  use Absinthe.Case, async: true

  import AssertResult

  describe "for arguments" do

    describe "provided flat" do

      describe "with a nullable deprecated arg" do

        it "shows a deprecation notice without a reason" do
          query = """
            query ThingByDeprecatedArg {
              thing(id: "foo", deprecatedArg: "dep") {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `deprecatedArg' (String): Deprecated"}]}}, result
        end

        it "shows a deprecation notice with a reason" do
          query = """
            query ThingByDeprecatedArgWithReason {
              thing(id: "foo", deprecatedArgWithReason: "dep") {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `deprecatedArgWithReason' (String): Deprecated; reason"}]}}, result
        end

      end

      describe "with a non-null deprecated arg" do

        it "shows a deprecation notice without a reason" do
          query = """
            query ThingByDeprecatedNonNullArg {
              thing(id: "foo", deprecatedNonNullArg: "dep") {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{locations: [%{column: 0, line: 2}], message: "Argument `deprecatedNonNullArg' (String): Deprecated"}]}}, result
        end

        it "shows a deprecation notice with a reason" do
          query = """
            query ThingByDeprecatedNonNullArgWithReason {
              thing(id: "foo", deprecatedNonNullArgWithReason: "dep") {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `deprecatedNonNullArgWithReason' (String): Deprecated; reason"}]}}, result
        end

      end

    end

    describe "provided in input objects" do

      describe "with a nullable deprecated field" do

        it "shows a deprecation notice without a reason" do
          query = """
            mutation UpdateThing {
              thing: updateThing(id: "foo", thing: {deprecatedField: "2"}) {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `thing.deprecatedField' (String): Deprecated"}]}}, result
        end

        it "shows a deprecation notice with a reason" do
          query = """
            mutation UpdateThing {
              thing: updateThing(id: "foo", thing: {deprecatedFieldWithReason: "2"}) {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `thing.deprecatedFieldWithReason' (String): Deprecated; reason"}]}}, result
        end

      end

      describe "with a non-null deprecated field" do

        it "shows a deprecation notice without a reason" do
          query = """
            mutation UpdateThing {
              thing: updateThing(id: "foo", thing: {deprecatedNonNullField: "2"}) {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `thing.deprecatedNonNullField' (String): Deprecated"}]}}, result
        end

        it "shows a deprecation notice with a reason" do
          query = """
            mutation UpdateThing {
              thing: updateThing(id: "foo", thing: {deprecatedNonNullFieldWithReason: "2"}) {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `thing.deprecatedNonNullFieldWithReason' (String): Deprecated; reason"}]}}, result
        end

      end

    end

  end

  describe "for fields" do

    it "shows a deprecation notice without a reason" do
      query = """
        query DeprecatedThing {
          thing: deprecatedThing(id: "foo") {
            name
          }
        }
      """
      result = run(query)
      assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                     errors: [%{message: "Field `deprecatedThing': Deprecated"}]}}, result
    end

    it "shows a deprecation notice with a reason" do
      query = """
        query DeprecatedThingWithReason {
          thing: deprecatedThingWithReason(id: "foo") {
            name
          }
        }
      """
      result = run(query)
      assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                     errors: [%{message: "Field `deprecatedThingWithReason': Deprecated; use `thing' instead"}]}}, result
    end

  end

  defp run(query, options \\ []) do
    query
    |> Absinthe.run(Things, options)
  end

end
