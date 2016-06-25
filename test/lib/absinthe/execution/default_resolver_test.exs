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

      default_resolve fn
        _, %{source: source, definition: %{name: name}} ->
          {
            :ok,
            Map.get(source, name) || Map.get(source, String.to_existing_atom(name))
          }
      end

    end

    it "should resolve using as defined" do
      assert {:ok, %{data: %{"foo" => "baz", "bar" => "quux"}}} == Absinthe.run(@query, CustomSchema, root_value: @root)
    end

  end

end
