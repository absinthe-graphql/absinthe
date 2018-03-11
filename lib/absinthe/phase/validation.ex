defmodule Absinthe.Phase.Validation do
  @moduledoc false

  alias Absinthe.Blueprint

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__).Helpers
    end
  end

  defmodule Helpers do
    @spec any_invalid?([Blueprint.node_t()]) :: boolean
    def any_invalid?(nodes) do
      Enum.any?(nodes, fn
        %{flags: %{invalid: _}} ->
          true

        _ ->
          false
      end)
    end
  end
end
