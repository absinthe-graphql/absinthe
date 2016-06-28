defmodule Absinthe.Language.ObjectDefinition do

  @moduledoc false

  defstruct name: nil, directives: [], interfaces: [], fields: [], loc: %{start_line: nil}
end
