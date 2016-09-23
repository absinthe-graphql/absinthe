defmodule Blueprint.Document do

  @type t ::
      Blueprint.Document.Field.t
    | Blueprint.Document.Fragment.t
    | Blueprint.Document.Operation.t
    | Blueprint.Document.VariableDefinition.t

  @type selection_t ::
      Field.t
    | Blueprint.Document.Fragment.Inline.t
    | Blueprint.Document.Fragment.Spread.t

end
