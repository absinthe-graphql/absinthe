defmodule Absinthe.Type.Enum do
  @moduledoc """
  Used to define an enum type, a special scalar that can only have a defined set
  of values.

  See the `t` type below for details and examples.

  ## Examples

  Given a type defined as the following (see `Absinthe.Schema.Notation`):

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

  alias Absinthe.{Blueprint, Type}

  @typedoc """
  A defined enum type.

  Should be defined using `Absinthe.Schema.Notation.enum/2`.

  * `:name` - The name of the enum type. Should be a TitleCased `binary`. Set automatically.
  * `:description` - A nice description for introspection.
  * `:values` - The enum values, usually provided using the `Absinthe.Schema.Notation.values/1` or `Absinthe.Schema.Notation.value/1` macro.


  The `__private__` and `:__reference__` fields are for internal use.
  """
  @type t :: %__MODULE__{
          name: binary,
          description: binary,
          values: %{binary => Type.Enum.Value.t()},
          identifier: atom,
          __private__: Keyword.t(),
          __reference__: Type.Reference.t()
        }

  defstruct name: nil,
            description: nil,
            identifier: nil,
            values: %{},
            values_by_internal_value: %{},
            values_by_name: %{},
            __private__: [],
            __reference__: nil

  def build(%{attrs: attrs}) do
    raw_values = attrs[:values] || []

    values = Type.Enum.Value.build(raw_values)
    internal_values = Type.Enum.Value.build(raw_values, :value)
    values_by_name = Type.Enum.Value.build(raw_values, :name)

    attrs =
      attrs
      |> Keyword.put(:values, values)
      |> Keyword.put(:values_by_internal_value, internal_values)
      |> Keyword.put(:values_by_name, values_by_name)

    quote do
      %unquote(__MODULE__){
        unquote_splicing(attrs)
      }
    end
  end

  # Get the internal representation of an enum value
  @doc false
  @spec parse(t, any) :: any
  def parse(enum, %Blueprint.Input.Enum{value: external_value}) do
    Map.fetch(enum.values_by_name, external_value)
  end

  def parse(_, _) do
    :error
  end

  # Get the external representation of an enum value
  @doc false
  @spec serialize(t, any) :: binary
  def serialize(enum, internal_value) do
    Map.fetch!(enum.values_by_internal_value, internal_value).name
  end
end
