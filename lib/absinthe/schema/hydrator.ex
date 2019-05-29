defmodule Absinthe.Schema.Hydrator do

  @callback hydrate(node :: Absinthe.Blueprint.Schema.t(), hydration :: any) ::
              Absinthe.Blueprint.Schema.t()

end
