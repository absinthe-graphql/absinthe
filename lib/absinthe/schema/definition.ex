defmodule Absinthe.Schema.Definition do
  alias Absinthe.Utils
  import Absinthe.Schema.TypeModule

  defmacro __using__(opts) do
    quote do
      use Absinthe.Schema.TypeModule
      import unquote(__MODULE__)
      import_types Absinthe.Type.BuiltIns, export: false
    end
  end

  defmacro query(name, blueprint) when is_binary(name) do
    quote do
      object [query: unquote(name)], unquote(blueprint), export: false
    end
  end
  defmacro query(blueprint) do
    quote do
      query "RootQueryType", unquote(blueprint)
    end
  end

  defmacro mutation(name, blueprint) when is_binary(name) do
    quote do
      object [mutation: unquote(name)], unquote(blueprint), export: false
    end
  end
  defmacro mutation(blueprint) do
    quote do
      mutation "RootMutationType", unquote(blueprint)
    end
  end

  defmacro subscription(name, blueprint) when is_binary(name) do
    quote do
      object [subscription: unquote(name)], unquote(blueprint), export: false
    end
  end
  defmacro subscription(blueprint) do
    quote do
      subscription "RootSubscriptionType", unquote(blueprint)
    end
  end

end
