defmodule Absinthe.Flag do

  @moduledoc false

  # Create a "flagged" tuple, supporting easy creation via |> pipes.
  #
  #     iex> :thing |> as(:ok)
  #     {:ok, :thing}
  #
  #     iex> :thing |> as(:error)
  #     {:error, :thing}
  #
  @doc false
  @spec as(any, atom) :: {atom, any}
  def as(value, flag) do
    {flag, value}
  end

end
