defmodule Absinthe.Execution.DefaultResolverTest do
  use Absinthe.Case, async: true

  @root %{:foo => "baz", "bar" => "quux", "foo_bar" => "quix"}
  @query "{ foo bar fooBar }"

  context "without a custom default resolver defined" do

    defmodule NormalSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
        field :bar, :string
        field :foo_bar, :string
      end

    end

    it "should resolve using atoms" do
      assert {:ok, %{data: %{"foo" => "baz", "bar" => nil, "fooBar" => nil}}} == Absinthe.run(@query, NormalSchema, root_value: @root)
    end

  end

  context "with a custom default resolver defined" do

    defmodule CustomSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
        field :bar, :string
        field :foo_bar, :string
      end

      def middleware([], %{name: name, identifier: identifier}, _) do
        middleware_spec = Absinthe.Resolution.resolver_spec(fn parent, _, _ ->
          case parent do
            %{^name => value} -> {:ok, value}
            %{^identifier => value} -> {:ok, value}
            _ -> {:ok, nil}
          end
        end)

        [middleware_spec]
      end
      def middleware(middleware, _, _) do
        middleware
      end

    end

    it "should resolve using strings or atoms" do
      assert {:ok, %{data: %{"foo" => "baz", "bar" => "quux", "fooBar" => "quix"}}} == Absinthe.run(@query, CustomSchema, root_value: @root)
    end

  end

end
