defmodule Absinthe.Introspection do

  @moduledoc """
  Introspection support.

  You can introspect your schema using `__schema`, `__type`, and `__typename`,
  as [described in the specification](https://facebook.github.io/graphql/#sec-Introspection).

  See [the PR](https://github.com/CargoSense/absinthe/pull/26) for details on
  limitations (notably enum values, union types, and directives cannot currently
  be introspected).
  """

end
