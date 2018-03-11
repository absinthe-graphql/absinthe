defmodule Absinthe.Schema.Notation.Definition do
  @moduledoc false
  defstruct category: nil,
            source: nil,
            identifier: nil,
            builder: nil,
            attrs: [],
            opts: [],
            file: nil,
            line: nil
end
