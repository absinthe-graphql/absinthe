defmodule Absinthe.Introspection.Kind do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
      def kind do
        __MODULE__
        |> Module.split()
        |> List.last()
        |> Absinthe.Introspection.Kind.upcase()
      end

      defoverridable kind: 0
    end
  end

  def upcase(name) do
    Regex.scan(~r{[A-Z]+[a-z]+}, name)
    |> List.flatten()
    |> Enum.map(&String.upcase/1)
    |> Enum.join("_")
  end

  @callback kind :: binary
end
