defmodule Absinthe.Schema.Definition do
  alias Absinthe.Utils

  defmacro __using__(opts) do
    quote do
      use Absinthe.Schema.TypeModule
      import_types Absinthe.Type.BuiltIns, export: false
    end
  end

end
