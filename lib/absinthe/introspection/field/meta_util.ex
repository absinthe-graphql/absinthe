defmodule Absinthe.Introspection.Field.MetaUtil do
  @moduledoc """
  Helper macros for exposing custom meta data

  example:
    defmodule MyMetaMod do
      require Absinthe.Introspection.Field.MetaUtil
      alias Absinthe.Introspection.Field.MetaUtil
      
      MetaUtil.expose_meta(:default, :string, "Field Default Value")
    end

    defmodule TestSchema do
      use Absinthe.Schema
      use Absinthe.Schema.Notation

      query do
        field :my_field, :string do
          meta :default, "my default value"
        end
      end
    end

    \"""
    query {
      __type(name: "RootQueryType") {
        fields {
          name
          __default
        }
      }
    }
    \"""
    |> Absinthe.run!(TestSchema)

  output:
    %{data: %{"__type" => 
              %{"fields" => [
                  %{"__default" => "my default value",
                    "name" => "myField"}]}}}

  """
  defmacro expose_meta(name,type,description) do
    quote do
      defmodule (unquote(Module.concat Absinthe.Introspection.Field.Meta,String.capitalize to_string(name))) do
        alias Absinthe.Type

        def meta() do
          %Type.Field{
            name: unquote("__#{name}"),
            type:  unquote(type),
            description: unquote(description),
            resolve: fn
              _, %{source: source} ->
                private = source[:__private__] || []
                meta_items = private[:meta] || []   
                {:ok, meta_items[unquote(name)]}
            end
          }
        end
      end
    end
  end
  
  defmacro expose_meta(name,type,description,resolve) do
    quote do
      defmodule (unquote(Module.concat Absinthe.Introspection.Field.Meta,String.capitalize to_string(name))) do
        alias Absinthe.Type

        def meta() do
          %Type.Field{
            name: unquote("__#{name}"),
            type:  unquote(type),
            description: unquote(description),
            resolve: unquote(resolve)
          }
        end
      end
    end
  end

end