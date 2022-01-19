defmodule Absinthe.Phase.Document.Validation.Utils.MessageSuggestions do
  @moduledoc false
  @suggest 5

  @doc """
  Generate an suggestions message for a incorrect field
  """
  def suggest_message(suggestions) do
    " Did you mean " <> to_quoted_or_list(suggestions |> Enum.take(@suggest)) <> "?"
  end

  def suggest_fragment_message(suggestions) do
    " Did you mean to use an inline fragment on " <>
      to_quoted_or_list(suggestions |> Enum.take(@suggest)) <> "?"
  end

  defp to_quoted_or_list([a]), do: ~s("#{a}")
  defp to_quoted_or_list([a, b]), do: ~s("#{a}" or "#{b}")
  defp to_quoted_or_list(other), do: to_longer_quoted_or_list(other)

  defp to_longer_quoted_or_list(list, acc \\ "")
  defp to_longer_quoted_or_list([word], acc), do: acc <> ~s(, or "#{word}")

  defp to_longer_quoted_or_list([word | rest], "") do
    rest
    |> to_longer_quoted_or_list(~s("#{word}"))
  end

  defp to_longer_quoted_or_list([word | rest], acc) do
    rest
    |> to_longer_quoted_or_list(acc <> ~s(, "#{word}"))
  end
end
