defmodule Absinthe.Blueprint.Document do
  @moduledoc false
  alias Absinthe.Blueprint

  @type t ::
          Blueprint.Document.Field.t()
          | Blueprint.Document.Fragment.t()
          | Blueprint.Document.Operation.t()
          | Blueprint.Document.VariableDefinition.t()

  @type selection_t ::
          Blueprint.Document.Field.t()
          | Blueprint.Document.Fragment.Inline.t()
          | Blueprint.Document.Fragment.Spread.t()
end
