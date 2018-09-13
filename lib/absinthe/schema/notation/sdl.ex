defmodule Absinthe.Schema.Notation.SDL do
  @moduledoc false

  @doc """
  Parse definitions from SDL source
  """
  @spec parse(sdl :: String.t(), Module.t()) ::
          {:ok, [Absinthe.Blueprint.Schema.type_t()]} | {:error, String.t()}
  def parse(sdl, module) do
    with {:ok, doc} <- Absinthe.Phase.Parse.run(sdl) do
      definitions =
        doc.input.definitions
        |> Enum.map(&Absinthe.Blueprint.Draft.convert(&1, doc))
        |> Enum.map(fn type -> %{type | module: module} end)

      {:ok, definitions}
    else
      {:error, %Absinthe.Blueprint{execution: %{validation_errors: [_ | _] = errors}}} ->
        error =
          errors
          |> Enum.map(&"#{&1.message} (#{inspect(&1.locations)})")
          |> Enum.join("\n")

        {:error, error}

      other ->
        other
    end
  end
end
