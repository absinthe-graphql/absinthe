defmodule Absinthe.Execution.DefaultResolverTest do
  use Absinthe.Case, async: true

  @root %{:foo => "baz", "bar" => "quux"}
  @query "{ foo bar }"

  describe "without a custom default resolver defined" do

    defmodule NormalSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
        field :bar, :string
      end

    end

    it "should resolve using atoms" do
      assert {:ok, %{data: %{"foo" => "baz", "bar" => nil}}} == Absinthe.run(@query, NormalSchema, root_value: @root)
    end

  end

  describe "with a custom default resolver defined" do

    defmodule CustomSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
        field :bar, :string
      end

      def middleware(%{middleware: [], name: name, identifier: identifier} = field, _) do
        middleware = Absinthe.Resolution.resolver(fn parent, _, _ ->
          case parent do
            %{^name => value} -> {:ok, value}
            %{^identifier => value} -> {:ok, value}
            _ -> {:ok, nil}
          end
        end)

        %{field | middleware: [middleware]}
      end
      def middleware(field, _) do
        field
      end

    end

    it "should resolve using as defined" do
      assert {:ok, %{data: %{"foo" => "baz", "bar" => "quux"}}} == Absinthe.run(@query, CustomSchema, root_value: @root)
    end

  end

end
