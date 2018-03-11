defmodule Absinthe.Utils.Suggestion do
  @jaro_threshold 0.70

  @doc """
  Sort a list of suggestions by Jaro distance to a target string,
  supporting a cut-off threshold.
  """
  @spec sort_list([String.t()], String.t(), float) :: [String.t()]
  def sort_list(suggestions, target, threshold \\ @jaro_threshold)

  def sort_list(suggestions, target, threshold) do
    Enum.map(suggestions, fn s -> {s, String.jaro_distance(s, target)} end)
    |> Enum.filter(fn {_, x} -> x >= threshold end)
    |> Enum.sort_by(fn {_, x} -> x end)
    |> Enum.map(fn {s, _} -> s end)
  end
end
