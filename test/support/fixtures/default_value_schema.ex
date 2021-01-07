defmodule Absinthe.Fixtures.DefaultValueSchema do
  use Absinthe.Schema
  use Absinthe.Fixture

  # Note: More examples in Absinthe.Fixtures.Query.TestSchemaFieldArgDefaultValueWithImportFields

  query do
    field :microsecond, :integer, default_value: DateTime.utc_now().microsecond |> elem(0)
  end
end
