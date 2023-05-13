defmodule Absinthe.Fixtures.InvalidInputTypesSdlSchema do
  use Absinthe.Schema

  import_sdl """
    type User {
      name: String
    }

    input Input {
      foo: String
    }

    type BadObject {
      blah: Input
    }

    type Query {
      foo(invalidArg: User): User
    }
  """
end
