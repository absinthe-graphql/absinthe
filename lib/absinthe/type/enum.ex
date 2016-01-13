defmodule Absinthe.Type.Enum do

  @moduledoc """
  Used to define an enum type, a special scalar that can only have a defined set
  of values.

  See the `t` type below for details and examples.

  ## Examples

  Given a type defined as the following (see `Absinthe.Type.Definitions`):

  ```
  @absinthe :type
  def color_channel do
    %Absinthe.Type.Enum{
      description: "The selected color channel",
      values: values(
        red: [
          description: "Color Red",
          value: :r
        ],
        green: [
          description: "Color Green",
          value: :g
        ],
        blue: [
          description: "Color Blue",
          value: :b
        ],
        alpha: deprecate([
          description: "Alpha",
          value: :a
        ], reason: "We no longer support opacity settings")
      )
    }
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
  values: values(
    red: [description: "Color Red"]
    ...
  )
  ```

  If you really want to use a shorthand, skipping support for descriptions,
  custom raw values, and deprecation, you can just provide a list of atoms:

  ```
  values: values([:red, :green, :blue, :alpha])
  ```

  Keep in mind that writing a terse definition that skips descriptions and
  deprecations today may hamper tooling that relies on introspection tomorrow.

  """

  use Absinthe.Introspection.Kind

  alias Absinthe.Type

  @type t :: %{name: binary, description: binary, values: %{binary => Type.Enum.Value.t}, reference: Type.Reference.t}
  defstruct name: nil, description: nil, values: %{}, reference: nil
end
