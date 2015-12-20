defmodule ExGraphQL.Flag do

  @doc """
  Create a "flagged" tuple, supporting easy creating via |> pipes.

  ## Examples

    iex> :thing |> as(:ok)
    {:ok, :thing}

    iex> :thing |> as(:error)
    {:error, :thing}

  """
  @spec as(any, atom) :: {atom, any}
  def as(value, flag) do
    {flag, value}
  end

end
