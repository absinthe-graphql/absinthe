defmodule Absinthe.Schema.Rule.ObjectMustDefineFieldsTest do
  use Absinthe.Case, async: true

  @schema ~S(
  defmodule InputObjectSchema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    import_sdl """
    input PetInput
    """
  end
  )

  test "errors on input object not declaring fields" do
    error = ~r/The input object type `pet_input` must define one or more fields./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@schema)
    end)
  end

  @schema ~S(
  defmodule ObjectSchema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    import_sdl """
    type Pet
    """
  end
  )
  test "errors on object not declaring fields" do
    error = ~r/The object type `pet` must define one or more fields./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@schema)
    end)
  end

  @schema ~S(
  defmodule InterfaceSchema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    import_sdl """
    interface Named
    """
  end
  )
  test "errors on interface not declaring fields" do
    error = ~r/The interface type `named` must define one or more fields./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@schema)
    end)
  end

  @schema ~S(
  defmodule QuerySchema do
    use Absinthe.Schema

    query do

    end
  end
  )
  test "errors on query not declaring fields" do
    error = ~r/The object type `query` must define one or more fields./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@schema)
    end)
  end

  @schema ~S(
  defmodule MutationSchema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    mutation do
    end
  end
  )
  test "errors on mutation not declaring fields" do
    error = ~r/The object type `mutation` must define one or more fields./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@schema)
    end)
  end

  @schema ~S(
  defmodule SubscriptionSchema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end

    subscription do
    end
  end
  )
  test "errors on subscription not declaring fields" do
    error = ~r/The object type `subscription` must define one or more fields./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@schema)
    end)
  end

  @schema ~S(
    defmodule ExtendObjectSchema do
      use Absinthe.Schema

      query do
        field :foo, :string
      end

      object :bar do
        field :baz, :string
      end

      extend object :bar do
      end
    end
    )
  test "does not error on empty object extension" do
    assert Code.eval_string(@schema)
  end
end
