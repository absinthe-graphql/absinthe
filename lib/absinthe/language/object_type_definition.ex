defmodule Absinthe.Language.ObjectTypeDefinition do

  @moduledoc false

  defstruct name: nil, directives: [], interfaces: [], fields: [], loc: %{start_line: nil}
end
