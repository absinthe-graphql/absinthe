defmodule Absinthe.StrictSchemaTest do
  use Absinthe.Case, async: true

  describe "directive strict adapter" do
    test "can use camelcase external name" do
      document = """
      query ($input: FooBarInput!) {
        fooBarQuery @fooBarDirective(bazQux: $input) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"fooBarQuery" => %{"naiveDatetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.StrictLanguageConventions,
          variables: variables
        )
      )
    end

    test "returns an error when underscore external name used" do
      document = """
      query ($input: FooBarInput!) {
        fooBarQuery @foo_bar_directive(bazQux: $input) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_error_message(
        "Unknown directive `foo_bar_directive`.",
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.StrictLanguageConventions,
          variables: variables
        )
      )
    end

    test "returns an error when underscore external name used in argument" do
      document = """
      query ($input: FooBarInput!) {
        fooBarQuery @fooBarDirective(baz_qux: $input) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_error_message(
        "Unknown argument \"baz_qux\" on directive \"@fooBarDirective\".",
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.StrictLanguageConventions,
          variables: variables
        )
      )
    end
  end

  describe "directive non-strict adapter" do
    test "can use camelcase external name" do
      document = """
      query ($input: FooBarInput!) {
        fooBarQuery @fooBarDirective(bazQux: $input) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"fooBarQuery" => %{"naiveDatetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.LanguageConventions,
          variables: variables
        )
      )
    end

    test "can use underscore external name" do
      document = """
      query ($input: FooBarInput!) {
        fooBarQuery @foo_bar_directive(bazQux: $input) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"fooBarQuery" => %{"naiveDatetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.LanguageConventions,
          variables: variables
        )
      )
    end

    test "can use underscore external name in argument" do
      document = """
      query ($input: FooBarInput!) {
        fooBarQuery @fooBarDirective(baz_qux: $input) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"fooBarQuery" => %{"naiveDatetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.LanguageConventions,
          variables: variables
        )
      )
    end
  end

  describe "query strict adapter" do
    test "can use camelcase external name" do
      document = """
      query ($input: FooBarInput!) {
        fooBarQuery(bazQux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"fooBarQuery" => %{"naiveDatetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.StrictLanguageConventions,
          variables: variables
        )
      )
    end

    test "returns an error when underscore external name used" do
      document = """
      query ($input: FooBarInput!) {
        foo_bar_query(bazQux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_error_message(
        "Cannot query field \"foo_bar_query\" on type \"RootQueryType\". Did you mean to use an inline fragment on \"RootQueryType\"?",
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.StrictLanguageConventions,
          variables: variables
        )
      )
    end

    test "returns an error when underscore external name used in argument" do
      document = """
      query ($input: FooBarInput!) {
        fooBarQuery(baz_qux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_error_message(
        "Unknown argument \"baz_qux\" on field \"fooBarQuery\" of type \"RootQueryType\".",
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.StrictLanguageConventions,
          variables: variables
        )
      )
    end
  end

  describe "query non-strict adapter" do
    test "can use camelcase external name" do
      document = """
      query ($input: FooBarInput!) {
        fooBarQuery(bazQux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"fooBarQuery" => %{"naiveDatetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.LanguageConventions,
          variables: variables
        )
      )
    end

    test "can use underscore external name" do
      document = """
      query ($input: FooBarInput!) {
        foo_bar_query(bazQux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naive_datetime
        }
      }
      """

      variables = %{"input" => %{"naive_datetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"foo_bar_query" => %{"naive_datetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.LanguageConventions,
          variables: variables
        )
      )
    end

    test "can use underscore external name in argument" do
      document = """
      query ($input: FooBarInput!) {
        fooBarQuery(baz_qux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"fooBarQuery" => %{"naiveDatetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.LanguageConventions,
          variables: variables
        )
      )
    end
  end

  describe "mutation strict adapter" do
    test "can use camelcase external name" do
      document = """
      mutation ($input: FooBarInput!) {
        fooBarMutation(bazQux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"fooBarMutation" => %{"naiveDatetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.StrictLanguageConventions,
          variables: variables
        )
      )
    end

    test "returns an error when underscore external name used" do
      document = """
      mutation ($input: FooBarInput!) {
        foo_bar_mutation(bazQux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_error_message(
        "Cannot query field \"foo_bar_mutation\" on type \"RootMutationType\". Did you mean to use an inline fragment on \"RootMutationType\"?",
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.StrictLanguageConventions,
          variables: variables
        )
      )
    end

    test "returns an error when underscore external name used in argument" do
      document = """
      mutation ($input: FooBarInput!) {
        fooBarMutation(baz_qux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_error_message(
        "Unknown argument \"baz_qux\" on field \"fooBarMutation\" of type \"RootMutationType\".",
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.StrictLanguageConventions,
          variables: variables
        )
      )
    end
  end

  describe "mutation non-strict adapter" do
    test "can use camelcase external name" do
      document = """
      mutation ($input: FooBarInput!) {
        fooBarMutation(bazQux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"fooBarMutation" => %{"naiveDatetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.LanguageConventions,
          variables: variables
        )
      )
    end

    test "can use underscore external name" do
      document = """
      mutation ($input: FooBarInput!) {
        foo_bar_mutation(bazQux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naive_datetime
        }
      }
      """

      variables = %{"input" => %{"naive_datetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"foo_bar_mutation" => %{"naive_datetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.LanguageConventions,
          variables: variables
        )
      )
    end

    test "can use underscore external name in argument" do
      document = """
      mutation ($input: FooBarInput!) {
        fooBarMutation(baz_qux: $input) @fooBarDirective(bazQux: {naiveDatetime: "2017-01-27T20:31:56"}) {
          naiveDatetime
        }
      }
      """

      variables = %{"input" => %{"naiveDatetime" => "2017-01-27T20:31:55"}}

      assert_data(
        %{"fooBarMutation" => %{"naiveDatetime" => "2017-01-27T20:31:55"}},
        run(document, Absinthe.Fixtures.StrictSchema,
          adapter: Absinthe.Adapter.LanguageConventions,
          variables: variables
        )
      )
    end
  end
end
