defmodule Blueprint.Document do

  @type t ::
      Blueprint.Document.Field.t
    | Blueprint.Document.Operation.t
    | Blueprint.Document.VariableDefinition.t

end
