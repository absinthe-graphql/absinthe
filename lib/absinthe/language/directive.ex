defmodule Absinthe.Language.Directive do

  @moduledoc false

  @type t :: %{name: binary, arguments: [Absinthe.Language.Argument],
               loc: Absinthe.Language.loc_t}
  defstruct name: nil, arguments: [], loc: %{start_line: nil}
end
