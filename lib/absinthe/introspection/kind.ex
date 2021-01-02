defmodule Absinthe.Introspection.Kind do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
      def kind do
        __MODULE__
        |> Module.split()
        |> List.last()
        |> Absinthe.Introspection.Kind.downcase()
        |> String.to_existing_atom()
      end

      defoverridable kind: 0
    end
  end

  def downcase(name) do
    Regex.scan(~r{[A-Z]+[a-z]+}, name)
    |> List.flatten()
    |> Enum.map(&String.downcase/1)
    |> Enum.join("_")
  end

  @callback kind :: atom
end
