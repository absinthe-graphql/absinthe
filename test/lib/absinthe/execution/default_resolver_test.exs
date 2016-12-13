defmodule Absinthe.Execution.DefaultResolverTest do
  use Absinthe.Case, async: true

  @root %{:foo => "baz", "bar" => "quux", "foo_bar" => "quix"}
  @query "{ foo bar fooBar }"

  describe "without a custom default resolver defined" do

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

  describe "with a custom default resolver defined" do

    defmodule CustomSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
        field :bar, :string
        field :foo_bar, :string
      end

      default_resolve fn
        _, %{source: source, definition: %{name: name}} ->
          {
            :ok,
            Map.get(source, name) || Map.get(source, String.to_existing_atom(name))
          }
      end

    end

    it "should resolve using strings or atoms" do
      assert {:ok, %{data: %{"foo" => "baz", "bar" => "quux", "fooBar" => "quix"}}} == Absinthe.run(@query, CustomSchema, root_value: @root)
    end

  end

end
