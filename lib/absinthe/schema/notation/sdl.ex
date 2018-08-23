defmodule Absinthe.Schema.Notation.SDL do
  @moduledoc false

  @doc """
  Parse definitions from SDL source
  """
  @spec parse(sdl :: String.t()) ::
          {:ok, [Absinthe.Blueprint.Schema.type_t()]} | {:error, String.t()}
  def parse(sdl) do
    with {:ok, doc} <- Absinthe.Phase.Parse.run(sdl) do
      definitions =
        doc.input.definitions
        |> Enum.map(&Absinthe.Blueprint.Draft.convert(&1, doc))

      {:ok, definitions}
    else
      {:error, %Absinthe.Blueprint{execution: %{validation_errors: errors}} = bp}
      when length(errors) > 0 ->
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
