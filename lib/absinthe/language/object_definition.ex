defmodule Absinthe.Language.ObjectDefinition do

  @moduledoc false

  defstruct name: nil, interfaces: [], fields: [], loc: %{start_line: nil}
end
