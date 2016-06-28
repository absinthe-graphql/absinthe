defmodule Absinthe.Language.InterfaceDefinition do

  @moduledoc false

  defstruct name: nil, fields: [], directives: [], loc: %{start_line: nil}
end
