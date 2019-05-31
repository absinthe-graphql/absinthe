defmodule Absinthe.Schema.Hydrator do
  @type hydration :: any

  @callback apply_hydration(
              node :: Absinthe.Blueprint.Schema.t(),
              hydration :: hydration
            ) :: Absinthe.Blueprint.Schema.t()
end
