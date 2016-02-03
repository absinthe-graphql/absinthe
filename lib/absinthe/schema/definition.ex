defmodule Absinthe.Schema.Definition do

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro query(attrs) do
  end

  defmacro mutation(attrs) do
  end

  defmacro object(identifier, attrs) do
    Absinthe.Type.Object.build(identifier, attrs)
  end

  defmacro interface(identifier, attrs) do
  end

  defmacro input_object(identifier, attrs) do
  end


end
