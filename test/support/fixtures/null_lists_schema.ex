defmodule Absinthe.Fixtures.NullListsSchema do
  use Absinthe.Schema

  query do
    field :nullable_list, :list_details do
      arg :input, list_of(:integer)

      resolve fn
        _, %{input: nil}, _ ->
          {:ok, nil}

        _, %{input: list}, _ ->
          {
            :ok,
            %{
              length: length(list),
              content: list,
              null_count: Enum.count(list, &(&1 == nil)),
              non_null_count: Enum.count(list, &(&1 != nil))
            }
          }
      end
    end

    field :non_nullable_list, :list_details do
      arg :input, non_null(list_of(:integer))

      resolve fn _, %{input: list}, _ ->
        {
          :ok,
          %{
            length: length(list),
            content: list,
            null_count: Enum.count(list, &(&1 == nil)),
            non_null_count: Enum.count(list, &(&1 != nil))
          }
        }
      end
    end

    field :nullable_list_of_non_nullable_type, :list_details do
      arg :input, list_of(non_null(:integer))

      resolve fn
        _, %{input: nil}, _ ->
          {:ok, nil}

        _, %{input: list}, _ ->
          {
            :ok,
            %{
              length: length(list),
              content: list,
              null_count: Enum.count(list, &(&1 == nil)),
              non_null_count: Enum.count(list, &(&1 != nil))
            }
          }
      end
    end

    field :non_nullable_list_of_non_nullable_type, :list_details do
      arg :input, non_null(list_of(non_null(:integer)))

      resolve fn _, %{input: list}, _ ->
        {
          :ok,
          %{
            length: length(list),
            content: list,
            null_count: Enum.count(list, &(&1 == nil)),
            non_null_count: Enum.count(list, &(&1 != nil))
          }
        }
      end
    end
  end

  object :list_details do
    field :length, :integer
    field :content, list_of(:integer)
    field :null_count, :integer
    field :non_null_count, :integer
  end
end
