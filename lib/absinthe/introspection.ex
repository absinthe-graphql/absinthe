defmodule Absinthe.Introspection do
  @moduledoc """
  Introspection support.

  You can introspect your schema using `__schema`, `__type`, and `__typename`,
  as [described in the specification](https://spec.graphql.org/October2021/#sec-Introspection).

  ## Examples

  Seeing the names of the types in the schema:

  ```
  \"""
  {
    __schema {
      types {
        name
      }
    }
  }
  \"""
  |> Absinthe.run(MyApp.Schema)
  {:ok,
    %{data: %{
      "__schema" => %{
        "types" => [
          %{"name" => "Boolean"},
          %{"name" => "Float"},
          %{"name" => "ID"},
          %{"name" => "Int"},
          %{"name" => "String"},
          ...
        ]
      }
    }}
  }
  ```

  Getting the name of the queried type:

  ```
  \"""
  {
    profile {
      name
      __typename
    }
  }
  \"""
  |> Absinthe.run(MyApp.Schema)
  {:ok,
    %{data: %{
      "profile" => %{
        "name" => "Joe",
        "__typename" => "Person"
      }
    }}
  }
  ```

  Getting the name of the fields for a named type:

  ```
  \"""
  {
    __type(name: "Person") {
      fields {
        name
        type {
          kind
          name
        }
      }
    }
  }
  \"""
  |> Absinthe.run(MyApp.Schema)
  {:ok,
    %{data: %{
      "__type" => %{
        "fields" => [
          %{
            "name" => "name",
            "type" => %{"kind" => "SCALAR", "name" => "String"}
          },
          %{
            "name" => "age",
            "type" => %{"kind" => "SCALAR", "name" => "Int"}
          },
        ]
      }
    }}
  }
  ```

  (Note that you may have to nest several depths of `type`/`ofType`, as
  type information includes any wrapping layers of [List](https://spec.graphql.org/October2021/#sec-List)
  and/or [NonNull](https://spec.graphql.org/October2021/#sec-Non-Null).)
  """

  alias Absinthe.Type

  # Determine if a term is an introspection type
  @doc false
  @spec type?(any) :: boolean
  def type?(%Type.Object{name: "__" <> _}), do: true
  def type?(_), do: false
end
