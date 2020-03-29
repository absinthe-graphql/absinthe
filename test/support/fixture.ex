defmodule Absinthe.Fixture do
  defmacro __using__(_) do
    if System.get_env("SCHEMA_PROVIDER") == "persistent_term" do
      quote do
        @schema_provider Absinthe.Schema.PersistentTerm
      end
    else
      quote do
        @schema_provider Absinthe.Schema.Compiled
      end
    end
  end
end
