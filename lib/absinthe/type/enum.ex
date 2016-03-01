defmodule Absinthe.Type.Enum do

  @moduledoc """
  Used to define an enum type, a special scalar that can only have a defined set
  of values.

  See the `t` type below for details and examples.

  ## Examples

  Given a type defined as the following (see `Absinthe.Schema.Definition`):

  ```
  @desc "The selected color channel"
  enum :color_channel do
    value :red, as: :r, description: "Color Red"
    value :green, as: :g, description: "Color Green"
    value :blue, as: :b, description: "Color Blue"
    value :alpha, as: :a, deprecate: "We no longer support opacity settings", description: "Alpha Channel"
  end
  ```

  The "ColorChannel" type (referred inside Absinthe as `:color_channel`) is an
  Enum type, with values with names "red", "green", "blue", and "alpha" that map
  to internal, raw values `:r`, `:g`, `:b`, and `:a`. The alpha color channel
  is deprecated, just as fields and arguments can be.

  You can omit the raw `value` if you'd like it to be the same as the
  identifier. For instance, in this example the `value` is automatically set to
  `:red`:

  ```
  enum :color_channel do
    description "The selected color channel"

    value :red, description: "Color Red"
    value :green, description: "Color Green"
    value :blue, description: "Color Blue"
    value :alpha, deprecate: "We no longer support opacity settings", description: "Alpha Channel"
  end
  ```

  If you really want to use a shorthand, skipping support for descriptions,
  custom raw values, and deprecation, you can just provide a list of atoms:

  ```
  enum :color_channel, values: [:red, :green, :blue, :alpha]
  ```

  Keep in mind that writing a terse definition that skips descriptions and
  deprecations today may hamper tooling that relies on introspection tomorrow.

  """

  use Absinthe.Introspection.Kind

  alias Absinthe.Type

  @typedoc """
  A defined enum type.

  Should be defined using `Absinthe.Schema.Definition.enum/2`.

  * `:name` - The name of the enum type. Should be a TitleCased `binary`. Set automatically.
  * `:description` - A nice description for introspection.
  * `:values` - The enum valuesn, usually provided using the `Absinthe.Schema.Notation.values/1` or `Absinthe.Schema.Notation.value/1` macro.

  The `:__reference__` key is for internal use.
  """
  @type t :: %{name: binary, description: binary, values: %{binary => Type.Enum.Value.t}, __reference__: Type.Reference.t}
  defstruct name: nil, description: nil, values: %{}, __reference__: nil


  def build(%{attrs: attrs}) do
    values = Type.Enum.Value.build(attrs[:values] || [])
    quote do: %unquote(__MODULE__){unquote_splicing(attrs), values: unquote(values)}
  end

  # Get the internal representation of an enum value
  @doc false
  @spec parse(t, any) :: any
  def parse(enum, external_value) do
    case get_value(enum, name: external_value) do
      nil ->
        nil
      value ->
        value.value
    end
  end

  # Get the external representation of an enum value
  @doc false
  @spec serialize(t, any) :: binary
  def serialize(enum, internal_value) do
    case get_value(enum, value: internal_value) do
      nil ->
        nil
      value ->
        value.name
    end
  end

  @doc false
  @spec get_value(t, Keyword.t) :: Type.Enum.Value.t | nil
  def get_value(enum, options \\ []) do
    do_get_value(enum, options |> Enum.into(%{}))
  end

  @spec do_get_value(t, map) :: Type.Enum.Value.t | nil
  defp do_get_value(enum, %{name: raw_name}) do
    lookup_value(enum, :name, raw_name |> to_string)
  end
  defp do_get_value(enum, %{value: value}) do
    lookup_value(enum, :value, value)
  end

  @spec lookup_value(t, atom, binary | nil) :: Type.Enum.Value.t | nil
  defp lookup_value(_enum, _field, nil) do
    nil
  end
  defp lookup_value(enum, :name, criteria) do
    enum.values
    |> Map.values
    |> Enum.find(&(&1.name == criteria))
  end
  defp lookup_value(enum, :value, criteria) do
    enum.values
    |> Map.values
    |> Enum.find(&(&1.value == criteria))
  end

end
