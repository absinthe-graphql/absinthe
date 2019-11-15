defmodule Absinthe.Fixtures.CompiledIntrospectionSchema do
  # Run introspection query on compile time without telemetry
  Absinthe.Schema.introspect(Absinthe.Fixtures.ContactSchema, telemetry: false)
end
