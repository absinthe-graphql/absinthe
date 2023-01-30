defmodule Absinthe.Fixtures.InvalidInputTypesSdlSchema do
  use Absinthe.Schema

  import_sdl """
    type User

    input Input

    type BadObject {
      blah: Input
    }

    type Query {
      foo(invalidArg: User): User
    }
  """
end
