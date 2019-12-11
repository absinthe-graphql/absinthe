defmodule Absinthe.Adapter.StrictLanguageConventions do
  @moduledoc """
  Strict version of `Absinthe.Adapter.LanguageConventions` that will reject
  improperly formatted external names.

  For example, this document:

  ```graphql
  {
    create_user(user_id: 2) {
      first_name
      last_name
    }
  }
  ```

  Would result in name-mismatch errors returned to the client.

  The client should instead send the camelcase variant of the names:

  ```graphql
  {
    createUser(userId: 2) {
      firstName
      lastName
    }
  }
  ```

  See `Absinthe.Adapter.LanguageConventions` for more information.
  """

  use Absinthe.Adapter

  @doc """
  Converts a camelCase to snake_case

  Returns `nil` if the converted internal name does not match the converted external name.

  See `Absinthe.Adapter.LanguageConventions.to_internal_name/2`
  """
  @impl Absinthe.Adapter
  def to_internal_name(external_name, role) do
    internal_name = Absinthe.Adapter.LanguageConventions.to_internal_name(external_name, role)

    if external_name == Absinthe.Adapter.LanguageConventions.to_external_name(internal_name, role) do
      internal_name
    else
      nil
    end
  end

  @doc """
  Converts a snake_case to camelCase

  See `Absinthe.Adapter.LanguageConventions.to_external_name/2`
  """
  @impl Absinthe.Adapter
  def to_external_name(internal_name, role) do
    Absinthe.Adapter.LanguageConventions.to_external_name(internal_name, role)
  end
end
