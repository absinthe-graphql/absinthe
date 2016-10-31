defmodule Absinthe.Blueprint.Input.Generated do
  @enforce_keys [:by]
  defstruct [:by]

  @moduledoc false

  # A number of phases need to check for `nil` normalized values. This is problematic
  # for situations where a value has been generated from a default value. This struct
  # can be placed on the normalized value to indicate that it is not null, but also
  # that it is not a proper blueprint input.
end
