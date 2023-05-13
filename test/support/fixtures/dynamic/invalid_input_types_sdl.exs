defmodule Absinthe.Fixtures.InvalidOutputTypesSdlSchema do
  use Absinthe.Schema

  import_sdl """
    type User {
      name: String
    }

    input Foo {
      blah: User
    }

    type Query {
      foo(arg: Foo): User
    }
  """
end
