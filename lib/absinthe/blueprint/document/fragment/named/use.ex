defmodule Absinthe.Blueprint.Document.Fragment.Named.Use do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name, :source_location]
  defstruct [
    :name,
    :source_location
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          source_location: nil | Blueprint.Document.SourceLocation.t()
        }
end
