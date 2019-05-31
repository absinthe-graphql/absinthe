defmodule Absinthe.Phase.Schema.InlineFunctionsTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema.Notation

    object :inlined do
      field :direct, :string, resolve: &__MODULE__.foo/3
      field :indirect, :string, resolve: indirection()
      field :via_callback, :string

      field :complexity_literal, :string do
        complexity 1
      end
    end

    object :not_inlined do
      field :local_capture, :string, resolve: &foo/3

      field :anon_function, :string, resolve: fn _, _, _ -> {:ok, "yo"} end
    end

    def foo(_, _, _), do: {:ok, "hey"}

    defp indirection() do
      &__MODULE__.foo/3
    end

    def middleware(_, %{identifier: :via_callback}, %{identifier: :inlined}) do
      [{{Absinthe.Resolution, :call}, &__MODULE__.foo/3}]
    end

    def middleware(middleware, _a, _b) do
      middleware
    end
  end

  setup_all do
    {:ok, %{bp: result()}}
  end

  describe "resolvers and middleware" do
    test "are inlined when they are a literal external function", %{bp: bp} do
      assert {{Absinthe.Resolution, :call}, &Schema.foo/3} in get_field(bp, :inlined, :direct).middleware

      assert {{Absinthe.Resolution, :call}, &Schema.foo/3} in get_field(bp, :inlined, :indirect).middleware

      assert {{Absinthe.Resolution, :call}, &Schema.foo/3} in get_field(
               bp,
               :inlined,
               :via_callback
             ).middleware
    end

    test "aren't inlined if they're a local capture", %{bp: bp} do
      assert [{{Absinthe.Middleware, :shim}, _}] =
               get_field(bp, :not_inlined, :local_capture).middleware
    end
  end

  describe "complexity" do
    test "is inlined when it's a literal", %{bp: bp} do
      assert 1 == get_field(bp, :inlined, :complexity_literal).complexity
    end
  end

  defp get_field(%{schema_definitions: [schema]}, object, field) do
    object = Enum.find(schema.type_artifacts, fn t -> t.identifier == object end)
    Map.fetch!(object.fields, field)
  end

  def result() do
    assert {:ok, bp, _} = Absinthe.Pipeline.run(Schema.__absinthe_blueprint__(), pipeline())
    bp
  end

  def pipeline() do
    Schema
    |> Absinthe.Pipeline.for_schema()
    |> Absinthe.Pipeline.from(Absinthe.Phase.Schema.Build)
    |> Absinthe.Pipeline.upto(Absinthe.Phase.Schema.InlineFunctions)
  end
end
