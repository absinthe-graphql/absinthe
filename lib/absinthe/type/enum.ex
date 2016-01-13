defmodule Absinthe.Type.Enum do

  @moduledoc """
  Used to define an enum type, a special scalar that can only have a defined set
  of values.

  See the `t` type below for details and examples.

  ## Examples

  Given a type defined as the following (see `Absinthe.Type.Definitions`):

  ```
  @absinthe :type
  def color do
    %Absinthe.Type.Enum{
      description: "The selected color",
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
          description: "Alpha Channel",
          value: :a
        ], reason: "We no longer support opacity settings")
      )
    }
  end
  ```

  The "Color" type (referred inside Absinthe as `:color`) is an Enum type, with
  values with names "red", "green", "blue", and "alpha" that map to internal
  values `:r`, `:g`, `:b`, and `:a`. The alpha "color" is deprecated, just as
  fields and arguments can be.
  """

  use Absinthe.Introspection.Kind

  alias Absinthe.Type

  @type t :: %{name: binary, description: binary, values: %{binary => Type.Enum.Value.t}, reference: Type.Reference.t}
  defstruct name: nil, description: nil, values: %{}, reference: nil
end
