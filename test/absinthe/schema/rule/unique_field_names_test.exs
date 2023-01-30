defmodule Absinthe.Schema.Rule.UniqueFieldNamesTest do
  use Absinthe.Case, async: true

  @duplicate_object_fields ~S(
  defmodule DuplicateObjectFields do
    use Absinthe.Schema

    query do
    end

    import_sdl """
      type Dog {
        name: String!
        name: String
      }
    """
  end
  )

  @duplicate_interface_fields ~S(
  defmodule DuplicateInterfaceFields do
    use Absinthe.Schema

    query do
    end

    import_sdl """
      interface Animal {
        tail: Boolean
        tail: Boolean
      }
    """
  end
  )

  @duplicate_input_fields ~S(
  defmodule DuplicateInputFields do
    use Absinthe.Schema

    query do
    end

    import_sdl """
      input AnimalInput {
        species: String!
        species: String!
      }
    """
  end
  )

  test "errors on non unique object field names" do
    error = ~r/The field \"name\" is not unique in type \"Dog\"./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@duplicate_object_fields)
    end)
  end

  test "errors on non unique interface field names" do
    error = ~r/The field \"tail\" is not unique in type \"Animal\"./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@duplicate_interface_fields)
    end)
  end

  test "errors on non unique input field names" do
    error = ~r/The field \"species\" is not unique in type \"AnimalInput\"./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@duplicate_input_fields)
    end)
  end
end
