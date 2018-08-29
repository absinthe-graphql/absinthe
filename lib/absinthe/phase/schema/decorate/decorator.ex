defmodule Absinthe.Phase.Schema.Decorate.Decorator do
  @callback apply_decoration(node :: Absinthe.Blueprint.Schema.t(), decoration :: any) ::
              Absinthe.Blueprint.Schema.t()
end
