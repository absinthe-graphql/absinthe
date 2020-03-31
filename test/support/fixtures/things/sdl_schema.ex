defmodule Absinthe.Fixtures.Things.SDLSchema do
  use Absinthe.Schema
  use Absinthe.Fixture

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

  @db %{
    "foo" => %{id: "foo", name: "Foo", value: 4},
    "bar" => %{id: "bar", name: "Bar", value: 5}
  }

  def hydrate(%Absinthe.Blueprint{}, _) do
    %{
      mutation: %{
        failing_thing: [
          resolve: &__MODULE__.resolve_failing_thing/3
        ]
      },
      query: %{
        bad_resolution: [
          resolve: &__MODULE__.resolve_bad/3
        ],
        number: [
          resolve: &__MODULE__.resolve_number/3
        ],
        thing_by_context: [
          resolve: &__MODULE__.resolve_things_by_context/3
        ],
        things: [
          resolve: &__MODULE__.resolve_things/3
        ],
        thing: [
          resolve: &__MODULE__.resolve_thing/3
        ],
        deprecated_thing: [
          resolve: &__MODULE__.resolve_thing/3
        ],
        deprecated_thing_with_reason: [
          resolve: &__MODULE__.resolve_thing/3
        ]
      }
    }
  end

  def hydrate(_node, _ancestors) do
    []
  end

  def resolve_failing_thing(_, %{type: :multiple}, _) do
    {:error, ["one", "two"]}
  end

  def resolve_failing_thing(_, %{type: :with_code}, _) do
    {:error, message: "Custom Error", code: 42}
  end

  def resolve_failing_thing(_, %{type: :without_message}, _) do
    {:error, code: 42}
  end

  def resolve_failing_thing(_, %{type: :multiple_with_code}, _) do
    {:error, [%{message: "Custom Error 1", code: 1}, %{message: "Custom Error 2", code: 2}]}
  end

  def resolve_failing_thing(_, %{type: :multiple_without_message}, _) do
    {:error, [%{message: "Custom Error 1", code: 1}, %{code: 2}]}
  end

  def resolve_bad(_, _, _) do
    :not_expected
  end

  def resolve_number(_, %{val: v}, _), do: {:ok, v |> to_string}
  def resolve_number(_, args, _), do: {:error, "got #{inspect(args)}"}

  def resolve_things_by_context(_, _, %{context: %{thing: id}}) do
    {:ok, @db |> Map.get(id)}
  end

  def resolve_things_by_context(_, _, _) do
    {:error, "No :id context provided"}
  end

  def resolve_things(_, _, _) do
    {:ok, @db |> Map.values() |> Enum.sort_by(& &1.id)}
  end

  def resolve_thing(_, %{id: id}, _) do
    {:ok, @db |> Map.get(id)}
  end
end
