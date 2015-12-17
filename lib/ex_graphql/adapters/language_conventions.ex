defmodule ExGraphQL.Adapters.LanguageConventions do
  use ExGraphQL.Adapter

  @moduledoc """
  This defines an adapter that supports GraphQL query documents in their
  conventional (in JS) camelcase notation, while allowing the schema to be
  defined using conventional (in Elixir) underscore (snakecase) notation, and
  tranforming the names as needed for lookups, results, and error messages.

  For example, this document:

    {
      myUser: createUser(userId: 2) {
        firstName
        lastName
      }
    }

  Would map to an internal schema that used the following names:

  * `create_user` instead of `createUser`
  * `user_id` instead of `userId`
  * `first_name` instead of `firstName`
  * `last_name` instead of `lastName`

  Likewise, the result of executing this (camelcase) query document against our
  (snakecase) schema would have its names transformed back into camelcase on the
  way out:

      %{
        data: %{
          "myUser" => %{
            "firstName" => "Joe",
            "lastName" => "Black"}
        },
        errors: []
      }

  Note variables are a client-facing concern (they may be provided as
  parameters), so variable names should match the convention of the query
  document (eg, camelCase).
  """

  def to_internal_name(nil, _role) do
    nil
  end
  def to_internal_name(camelized_name, _role) do
    camelized_name
    |> Macro.underscore
  end

  def to_external_name(nil, _role) do
    nil
  end
  def to_external_name(underscored_name, _role) do
    underscored_name
    |> camelize_lower
  end

  defp camelize_lower(underscored) do
    [first, rest] = underscored
    |> Macro.camelize
    |> String.split("", parts: 2)
    String.downcase(first) <> rest
  end

end
