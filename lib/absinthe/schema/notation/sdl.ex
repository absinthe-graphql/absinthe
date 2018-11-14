defmodule Absinthe.Schema.Notation.SDL do
  @moduledoc false

  @doc """
  Parse definitions from SDL source
  """
  @spec parse(sdl :: String.t(), Module.t(), map())  ::
          {:ok, [Absinthe.Blueprint.Schema.type_t()]} | {:error, String.t()}
  def parse(sdl, module, ref) do
    with {:ok, doc} <- Absinthe.Phase.Parse.run(sdl) do
      definitions =
        doc.input.definitions
        |> Enum.map(&Absinthe.Blueprint.Draft.convert(&1, doc))
        |> Enum.map(&put_ref(&1, ref))
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

  defp put_ref(%{fields: fields} = node, ref) do
    %{node | fields: Enum.map(fields, &put_ref(&1, ref))}
    |> do_put_ref(ref)
  end
  defp put_ref(%{arguments: args} = node, ref) do
    %{node | arguments: Enum.map(args, &put_ref(&1, ref))}
    |> do_put_ref(ref)
  end
  defp put_ref(%{directives: dirs} = node, ref) do
    %{node | directives: Enum.map(dirs, &put_ref(&1, ref))}
    |> do_put_ref(ref)
  end
  defp put_ref(node, ref), do: do_put_ref(node, ref)

  defp do_put_ref(%{__reference__: nil} = node, ref), do: Map.put(node, :__reference__, ref)
  defp do_put_ref(node, _ref), do: node

end
