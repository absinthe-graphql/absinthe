defmodule BlueprintHelpers do

  alias Absinthe.Blueprint

  @spec named(Blueprint.node_t, module, String.t) :: nil | Blueprint.node_t
  def named(scope, mod, name) do
    Blueprint.find(scope, fn
      %{__struct__: ^mod, alias: ^name} ->
        true
      %{__struct__: ^mod, name: ^name} ->
        true
      _ ->
        false
    end)
  end

end
