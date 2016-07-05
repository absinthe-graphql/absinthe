defmodule Blueprint.TypeReference do

  alias __MODULE__

  @type t ::
      TypeReference.List.t
    | TypeReference.Name.t
    | TypeReference.NonNull.t

end
