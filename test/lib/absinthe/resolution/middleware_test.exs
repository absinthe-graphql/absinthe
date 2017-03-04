defmodule Absinthe.MiddlewareTest do
  use Absinthe.Case, async: true

  defmodule Timing do
    def call(res, :start) do
      # place start time on res
      res
    end

    def call(res, :end) do
      # put total time on res
      res
    end
  end

  defmodule Auth do
    def call(res, _) do
      case res.context do
        %{current_user: _} ->
          res
        _ ->
          %{res | state: :halt}
          |> Absinthe.Resolution.put_result({:error, "unauthorized"})
      end
    end
  end

  defmodule Schema do
    use Absinthe.Schema

    alias Absinthe.MiddlewareTest

    def middleware(field, object = %Absinthe.Type.Object{identifier: :secret_object}) do
      field
      |> Absinthe.Schema.default_middleware(object)
      |> Map.update!(:middleware, &[Absinthe.Middleware.plug(MiddlewareTest.Auth) | &1])
    end
    def middleware(field, _) do
      field
    end

    query do
      field :authenticated, :user do
        plug MiddlewareTest.Auth

        resolve fn _, _, _ ->
          {:ok, %{name: "bob"}}
        end
      end

      field :public, :user do
        resolve fn _, _, _ ->
          {:ok, %{name: "bob", email: "secret"}}
        end
      end

      field :returns_private_object, :secret_object do
        resolve fn _, _, _ ->
          {:ok, %{key: "value"}}
        end
      end
    end

    # keys in this object are made secret via the def middleware callback
    object :secret_object do
      field :key, :string
      field :key2, :string
    end

    object :user do
      field :email, :string do
        plug MiddlewareTest.Auth
        plug Absinthe.Middleware.Default, :email
      end
      field :name, :string
    end
  end

  test "fails with authorization error when no current user" do
    doc = """
    {authenticated { name }}
    """
    assert {:ok, %{errors: errors}} = Absinthe.run(doc, __MODULE__.Schema)
    assert [%{locations: [%{column: 0, line: 1}], message: "In field \"authenticated\": unauthorized"}] == errors
  end

  test "email fails with authorization error when no current user" do
    doc = """
    {public { name email }}
    """
    assert {:ok, %{errors: errors}} = Absinthe.run(doc, __MODULE__.Schema)
    assert [%{locations: [%{column: 0, line: 1}], message: "In field \"email\": unauthorized"}] == errors
  end

  test "email works when current user" do
    doc = """
    {public { name email }}
    """
    assert {:ok, %{data: data}} = Absinthe.run(doc, __MODULE__.Schema, context: %{current_user: %{}})
    assert %{"public" => %{"email" => "secret", "name" => "bob"}} == data
  end

  test "secret object cant be accessed without a current user" do
    doc = """
    {returnsPrivateObject { key }}
    """
    assert {:ok, %{errors: errors}} = Absinthe.run(doc, __MODULE__.Schema)
    assert [%{locations: [%{column: 0, line: 1}],
               message: "In field \"key\": unauthorized"}] == errors
  end
end
