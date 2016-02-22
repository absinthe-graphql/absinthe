defmodule Absinthe.Type.Deprecation do

  @moduledoc false

  @type t :: %{reason: binary}
  defstruct reason: nil

  @doc """
  Build a Deprecation struct (or return `nil`) for a value.
  """
  @spec build(nil | boolean | binary) :: nil | t
  def build(nil), do: nil
  def build(false), do: nil
  def build(true) do
    quote do: %unquote(__MODULE__){}
  end
  def build(reason) when is_binary(reason) do
    quote do: %unquote(__MODULE__){reason: unquote(reason)}
  end

end
