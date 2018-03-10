defmodule Absinthe.Schema.Experimental do
  defmacro __using__(_opt) do
    quote do
      use Absinthe.Schema.Notation.Experimental
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      # TODO: Run pipeline on @absinthe_blueprint
    end
  end
end
