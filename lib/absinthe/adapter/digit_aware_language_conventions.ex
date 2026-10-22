defmodule Absinthe.Adapter.DigitAwareLanguageConventions do
  use Absinthe.Adapter
  alias Absinthe.Utils

  @moduledoc """
  An adapter that extends the behavior of `Absinthe.Adapter.LanguageConventions`
  with correct roundtrip handling of field names containing digits.

  ## The problem with `LanguageConventions`

  `Macro.underscore/1` does not insert underscores at letter-to-digit boundaries.
  This means that names like `requires_2fa` get camelized to `"requires2fa"`, but
  converting back with `Macro.underscore/1` returns `"requires2fa"` instead of
  `"requires_2fa"` - the roundtrip breaks and the field becomes unreachable.

  ## How this adapter works

  - `to_external_name/2` behaves identically to `LanguageConventions` (camelCase output).
  - `to_internal_name/2` applies `Macro.underscore/1` and then inserts underscores
    at letter-to-digit boundaries. This ensures that names like `"requires2fa"`
    correctly resolve to `"requires_2fa"`.

  ## Examples

      iex> alias Absinthe.Adapter.DigitAwareLanguageConventions, as: Adapter
      iex> Adapter.to_internal_name("requires2fa", :field)
      "requires_2fa"
      iex> Adapter.to_internal_name("workPhone2", :field)
      "work_phone_2"
      iex> Adapter.to_internal_name("field2Name", :field)
      "field_2_name"
      iex> Adapter.to_internal_name("addressLine1", :field)
      "address_line_1"

  ## When to use this adapter

  Use this adapter instead of `LanguageConventions` if your schema includes fields
  with digits preceded by underscores (e.g., `:requires_2fa`, `:address_line_1`).

  Note that this adapter always inserts underscores at letter-to-digit boundaries
  during `to_internal_name/2`. If your schema includes field names where a digit
  is part of the word without a preceding underscore (e.g., `:req1` rather than
  `:req_1`), those names will not resolve correctly with this adapter. In that case,
  use `LanguageConventions` instead.
  """

  @doc "Converts a camelCase name to snake_case, handling letter-to-digit boundaries"
  @impl Absinthe.Adapter
  def to_internal_name(nil, _role) do
    nil
  end

  def to_internal_name("__" <> camelized_name, role) do
    "__" <> to_internal_name(camelized_name, role)
  end

  def to_internal_name(camelized_name, _role) when is_binary(camelized_name) do
    camelized_name
    |> Macro.underscore()
    |> insert_digit_underscores()
  end

  @doc "Converts a snake_case name to camelCase"
  @impl Absinthe.Adapter
  def to_external_name(nil, _role) do
    nil
  end

  def to_external_name("__" <> underscored_name, role) do
    "__" <> to_external_name(underscored_name, role)
  end

  def to_external_name(<<c::utf8, _::binary>> = name, _) when c in ?A..?Z do
    name |> Utils.camelize()
  end

  def to_external_name(underscored_name, _role) when is_binary(underscored_name) do
    underscored_name
    |> Utils.camelize(lower: true)
  end

  # Insert underscores between a lowercase letter and a digit.
  # "requires2fa" -> "requires_2fa"
  # "work_phone2" -> "work_phone_2"
  defp insert_digit_underscores(name) do
    String.replace(name, ~r/([a-z])(\d)/, "\\1_\\2")
  end
end
