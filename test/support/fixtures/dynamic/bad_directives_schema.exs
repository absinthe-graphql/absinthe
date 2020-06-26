defmodule Absinthe.TestSupport.Schema.BadDirectivesSchema do
  use Absinthe.Schema

  directive :mydirective do
  end

  directive :mydirective2 do
    on :unknown
  end

  query do
  end
end
