defmodule Absinthe.Type.Fetch do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      def fetch(container, key) do
        if Map.has_key?(container, key) do
          {:ok, container |> Map.get(key)}
        else
          :error
        end
      end
    end
  end
end
