defmodule Absinthe.Fixtures.StrictSchema do
  use Absinthe.Schema
  use Absinthe.Fixture

  import_types Absinthe.Type.Custom

  directive :foo_bar_directive do
    arg :baz_qux, non_null(:foo_bar_input)
    on [:field]

    expand fn %{baz_qux: %{naive_datetime: naive_datetime}}, node = %{flags: flags} ->
      %{node | flags: Map.put(flags, :baz_qux, naive_datetime)}
    end
  end

  input_object :foo_bar_input do
    field :naive_datetime, non_null(:naive_datetime)
  end

  object :foo_bar_object do
    field :naive_datetime, non_null(:naive_datetime)
  end

  query do
    field :foo_bar_query, :foo_bar_object do
      arg :baz_qux, :foo_bar_input

      resolve fn
        %{baz_qux: %{naive_datetime: naive_datetime}}, _ ->
          {:ok, %{naive_datetime: naive_datetime}}

        _, %{definition: %{flags: %{baz_qux: naive_datetime}}} ->
          {:ok, %{naive_datetime: naive_datetime}}

        _, _ ->
          {:ok, nil}
      end
    end
  end

  mutation do
    field :foo_bar_mutation, :foo_bar_object do
      arg :baz_qux, :foo_bar_input

      resolve fn
        %{baz_qux: %{naive_datetime: naive_datetime}}, _ ->
          {:ok, %{naive_datetime: naive_datetime}}

        _, %{definition: %{flags: %{baz_qux: naive_datetime}}} ->
          {:ok, %{naive_datetime: naive_datetime}}

        _, _ ->
          {:ok, nil}
      end
    end
  end
end
