defmodule Absinthe.Type.UndefinedDefault do
  @moduledoc false

  use Absinthe.Introspection.Kind
  use Absinthe.Type.Fetch

  @typedoc """
  Definition to undefined default values.

  ## Options

  * `:of_type` -- the underlying type to wrap
  """
  defstruct of_type: nil

  @type t :: %__MODULE__{of_type: Absinthe.Type.nullable_t()}
  @type t(x) :: %__MODULE__{of_type: x}
end
