defmodule Absinthe.Case do
  defmacro __using__(opts) do
    opts = Keyword.drop(opts, [:phase, :schema])

    quote do
      use ExUnit.Case, unquote(opts)
      import Absinthe.Case.Helpers.SchemaImplementations
      import Absinthe.Case.Helpers.Run
      import Absinthe.Case.Assertions.Result
      import Absinthe.Case.Assertions.Schema
    end
  end
end
