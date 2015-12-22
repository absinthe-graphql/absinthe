defmodule SpecificationVerification do

  defmacro __using__(options) do
    opts = options |> Keyword.put(:specification, true)
    quote do
      @moduletag unquote(opts)
    end
  end

end
