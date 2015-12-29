defmodule Absinthe.Execution.DeprecationTest do
  use ExSpec, async: true

  import AssertResult

  describe "for arguments" do

    describe "provided flat" do

      describe "with a nullable deprecated arg" do

        it "shows a deprecation notice without a reason" do
          query = """
            query ThingByDeprecatedArg {
              thing(id: "foo", deprecated_arg: "dep") {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `deprecated_arg' (String): Deprecated"}]}}, result
        end

        it "shows a deprecation notice with a reason" do
          query = """
            query ThingByDeprecatedArgWithReason {
              thing(id: "foo", deprecated_arg_with_reason: "dep") {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `deprecated_arg_with_reason' (String): Deprecated; reason"}]}}, result
        end

      end

      describe "with a non-null deprecated arg" do

        it "shows a deprecation notice without a reason" do
          query = """
            query ThingByDeprecatedNonNullArg {
              thing(id: "foo", deprecated_non_null_arg: "dep") {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{locations: [%{column: 0, line: 2}], message: "Argument `deprecated_non_null_arg' (String): Deprecated"}]}}, result
        end

        it "shows a deprecation notice with a reason" do
          query = """
            query ThingByDeprecatedNonNullArgWithReason {
              thing(id: "foo", deprecated_non_null_arg_with_reason: "dep") {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `deprecated_non_null_arg_with_reason' (String): Deprecated; reason"}]}}, result
        end

      end

    end

    describe "provided in input objects" do

      describe "with a nullable deprecated field" do

        it "shows a deprecation notice without a reason" do
          query = """
            mutation UpdateThing {
              thing: update_thing(id: "foo", thing: {deprecated_field: 2}) {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `thing.deprecated_field' (String): Deprecated"}]}}, result
        end

        it "shows a deprecation notice with a reason" do
          query = """
            mutation UpdateThing {
              thing: update_thing(id: "foo", thing: {deprecated_field_with_reason: 2}) {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `thing.deprecated_field_with_reason' (String): Deprecated; reason"}]}}, result
        end

      end

      describe "with a non-null deprecated field" do

        it "shows a deprecation notice without a reason" do
          query = """
            mutation UpdateThing {
              thing: update_thing(id: "foo", thing: {deprecated_non_null_field: 2}) {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `thing.deprecated_non_null_field' (String): Deprecated"}]}}, result
        end

        it "shows a deprecation notice with a reason" do
          query = """
            mutation UpdateThing {
              thing: update_thing(id: "foo", thing: {deprecated_non_null_field_with_reason: 2}) {
                name
              }
            }
          """
          result = run(query)
          assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                         errors: [%{message: "Argument `thing.deprecated_non_null_field_with_reason' (String): Deprecated; reason"}]}}, result
        end

      end

    end

  end

  describe "for fields" do

    it "shows a deprecation notice without a reason" do
      query = """
        query DeprecatedThing {
          thing: deprecated_thing(id: "foo") {
            name
          }
        }
      """
      result = run(query)
      assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                     errors: [%{message: "Field `deprecated_thing': Deprecated"}]}}, result
    end

    it "shows a deprecation notice with a reason" do
      query = """
        query DeprecatedThingWithReason {
          thing: deprecated_thing_with_reason(id: "foo") {
            name
          }
        }
      """
      result = run(query)
      assert_result {:ok, %{data: %{"thing" => %{"name" => "Foo"}},
                     errors: [%{message: "Field `deprecated_thing_with_reason': Deprecated; use `thing' instead"}]}}, result
    end

  end

  defp run(query, options \\ []) do
    query
    |> Absinthe.run(Things.schema, options)
  end

end
