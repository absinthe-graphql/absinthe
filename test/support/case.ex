defmodule Absinthe.Case do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      import Absinthe.Case.Helpers.Run
      import Absinthe.Case.Assertions.Result
      import Absinthe.Case.Assertions.Schema
    end
  end
end
