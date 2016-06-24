defmodule Absinthe.Case do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      import ExUnit.Case, except: [describe: 2]
      import ExSpec

      Module.put_attribute(__MODULE__, :ex_spec_contexts, [])
    end
  end
end
