defmodule Absinthe.Type.Deprecation do
  @moduledoc false

  @type t :: %{reason: binary}
  defstruct reason: nil
end
