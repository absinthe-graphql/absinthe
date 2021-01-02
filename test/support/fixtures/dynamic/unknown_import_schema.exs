defmodule Absinthe.TestSupport.Schema.UnknownImportSchema do
  use Absinthe.Schema

  import_types Test.Unknown

  query do
  end
end
