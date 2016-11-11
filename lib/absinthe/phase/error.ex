defmodule Absinthe.Phase.Error do

  @moduledoc false

  @enforce_keys [:message, :phase]
  defstruct [
    :message,
    :phase,
    locations: [],
    extra: []
  ]

  @type loc_t :: %{line: integer, column: nil | integer}

  @type t :: %__MODULE__{
    message: String.t,
    phase: module,
    locations: [loc_t],
    extra: Keyword.t
  }

  @doc """
  Generate a phase error that relates to a specific point in the
  document.
  """
  @spec new(Absinthe.Phase.t, String.t, loc_t | [loc_t]) :: t
  @spec new(Absinthe.Phase.t, String.t, loc_t | [loc_t], Keyword.t) :: t
  def new(phase, message, location, extra \\ []) do
    %__MODULE__{
      phase: phase,
      message: message,
      locations: List.wrap(location),
      extra: Enum.filter(extra, &filter_extra_item/1)
    }
  end

  @doc """
  Generate a phase error that doesn't relate to a specific point in the
  document.
  """
  @spec new(Absinthe.Phase.t, String.t) :: t
  def new(phase, message) do
    %__MODULE__{
      phase: phase,
      message: message
    }
  end


  defp filter_extra_items([]), do: true

  defp filter_extra_items([item | rem]) do
    filter_extra_item(item) && filter_extra_items(rem)
  end

  defp filter_extra_items(_attributes), do: false


  defp filter_extra_item({key, value}) do
    filter_extra_key(key) && filter_extra_value(value)
  end

  defp filter_extra_item(_item), do: false


  defp filter_extra_key(key) when is_atom(key), do: true

  defp filter_extra_key(_key), do: false


  defp filter_extra_value(value) when is_number(value), do: true

  defp filter_extra_value(value) when is_binary(value), do: true

  defp filter_extra_value(value) when is_atom(value), do: true

  defp filter_extra_value(value) when is_map(value) do
    filter_extra_items(Enum.to_list(value))
  end

  defp filter_extra_value([]), do: true

  defp filter_extra_value([value | rem]) do
    filter_extra_value(value) && filter_extra_value(rem)
  end

  defp filter_extra_value(_value), do: false



end
