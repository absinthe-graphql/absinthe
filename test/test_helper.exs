ExUnit.configure(exclude: [pending: true], timeout: 30_000)
ExUnit.start()

fixtures_schemas = [
  Absinthe.Fixtures.ArgumentsSchema,
  Absinthe.Fixtures.ColorSchema,
  Absinthe.Fixtures.ContactSchema,
  Absinthe.Fixtures.CustomTypesSchema,
  Absinthe.Fixtures.IdTestSchema,
  Absinthe.Fixtures.NullListsSchema,
  Absinthe.Fixtures.ObjectTimesSchema,
  Absinthe.Fixtures.OnlyQuerySchema,
  Absinthe.Fixtures.PetsSchema,
  Absinthe.Fixtures.StrictSchema,
  Absinthe.Fixtures.TimesSchema,
  Absinthe.Fixtures.Things.SDLSchema,
  Absinthe.Fixtures.Things.MacroSchema
]

for schema <- fixtures_schemas do
  Absinthe.Schema.Manager.start_link(schema)
end
