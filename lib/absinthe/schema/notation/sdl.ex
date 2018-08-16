defmodule Absinthe.Schema.Notation.SDL do
  @moduledoc false
  
  @doc """
  Parse definitions from SDL source
  """
  @spec parse(sdl :: String.t()) :: {:ok, [Absinthe.Blueprint.Schema.type_t()]} | {:error, String.t()}
  def parse(sdl) do
    with {:ok, doc} <- Absinthe.Phase.Parse.run(sdl) do
      definitions =
        doc.input.definitions
        |> Enum.map(&Absinthe.Blueprint.Draft.convert(&1, doc))
      {:ok, definitions}
    end
  end
  
end