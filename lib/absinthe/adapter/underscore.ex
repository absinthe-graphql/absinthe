defmodule Absinthe.Adapter.Underscore do
  @moduledoc """
  Underscores external input and leaves external input alone. Unlike the
  `Absinthe.Adapter.Passthrough` this does not break introspection (because
  introspection relies on underscoring incoming introspection queries which we
  still do).
  """

  use Absinthe.Adapter

  def to_internal_name(nil, _role) do
    nil
  end

  def to_internal_name("__" <> camelized_name, role) do
    "__" <> to_internal_name(camelized_name, role)
  end

  def to_internal_name(camelized_name, _role) do
    camelized_name
    |> Macro.underscore()
  end

  def to_external_name(name, _role) do
    name
  end
end
