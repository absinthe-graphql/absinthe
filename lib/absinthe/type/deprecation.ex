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

  @doc """
  Convert a `:deprecate` attr to a Deprecation struct
  """
  @spec from_attribute(Keyword.t()) :: Keyword.t()
  def from_attribute(attrs) do
    attrs
    |> Keyword.put(:deprecation, build(attrs[:deprecate]))
    |> Keyword.delete(:deprecate)
  end
end
