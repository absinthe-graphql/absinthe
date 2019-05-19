defmodule Absinthe.Fixtures.Things.SDLSchema do
  use Absinthe.Schema

  import_sdl """
  enum SigilsWork {
    FOO
    BAR
  }

  enum SigilsWorkInside {
    FOO
    BAR
  }

  enum FailureType {
    MULTIPLE
    WITH_CODE
    WITHOUT_MESSAGE
    MULTIPLE_WITH_CODE
    MULTIPLE_WITHOUT_MESSAGE
  }

  type RootMutationType {
    updateThing(id: String!, thing: InputThing!): Thing

    failingThing(type: FailureType): Thing
  }

  type RootQueryType {
    version: String

    badResolution: Thing

    number(val: Int!): String

    thingByContext: Thing

    things: [Thing]

    thing(
      "id of the thing"
      id: String!,

      "This is a deprecated arg"
      deprecatedArg: String @deprecated,

      "This is a non-null deprecated arg"
      deprecatedNonNullArg: String! @deprecated,

      "This is a deprecated arg with a reason"
      deprecatedArgWithReason: String @deprecated(reason: "reason"),

      "This is a non-null deprecated arg with a reason"
      deprecatedNonNullArgWithReason: String! @deprecated(reason: "reason")
    ): Thing

    deprecatedThing(
      "id of the thing"
      id: String!
    ): Thing @deprecated

    deprecatedThingWithReason(
      "id of the thing"
      id: String!
    ): Thing @deprecated(reason: "use `thing' instead")
  }

  "A thing as input"
  input InputThing {
    value: Int
    deprecatedField: String @deprecated,
    deprecatedFieldWithReason: String @deprecated(reason: "reason")
    deprecatedNonNullField: String! @deprecated
  }

  "A thing"
  type Thing {
    fail(
      "the id we want this field to fail on"
      id: ID
    ): ID

    "The ID of the thing"
    id: String!

    "The name of the thing"
    name: String

    "The value of the thing"
    value: Int

    otherThing: Thing
  }

  schema {
    mutation: RootMutationType
    query: RootQueryType
  }

  """

end
