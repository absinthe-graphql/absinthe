defmodule Absinthe.Case do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      import Absinthe.Case.Run
      import Absinthe.Case.Assertions
    end
  end
end
