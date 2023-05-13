defmodule Absinthe.Schema.Rule.ObjectInterfacesMustBeValidTest do
  use Absinthe.Case, async: true

  @interface_transitive_interfaces ~S(
  defmodule InterfaceWithTransitiveInterfaces do
    use Absinthe.Schema

    query do
    end

    import_sdl """
    interface Node {
      id: ID!
    }

    interface Resource implements Node {
      id: ID!
      url: String
    }

    # should also implement Node
    interface Image implements Resource  {
      id: ID!
      url: String
      thumbnail: String
    }
    """
  end
  )

  test "errors on interface not implementing all transitive interfaces" do
    error =
      ~r/Type \"image\" must implement interface type \"node\" because it is implemented by \"resource\"./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@interface_transitive_interfaces)
    end)
  end

  @object_transitive_interfaces ~S(
  defmodule ObjectWithTransitiveInterfaces do
    use Absinthe.Schema

    query do
    end

    import_sdl """
    interface Node {
      id: ID!
    }

    interface Resource implements Node {
      id: ID!
      url: String
    }

    # should also implement Node
    type Image implements Resource  {
      id: ID!
      url: String
      thumbnail: String
    }
    """
  end
  )

  test "errors on object not implementing all transitive interfaces" do
    error =
      ~r/Type \"image\" must implement interface type \"node\" because it is implemented by \"resource\"./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@object_transitive_interfaces)
    end)
  end
end
