defmodule Absinthe.Schema.Hydrator do
  @callback apply_hydration(
              node :: Absinthe.Blueprint.Schema.t(),
              hydration :: any
            ) :: Absinthe.Blueprint.Schema.t()
end
