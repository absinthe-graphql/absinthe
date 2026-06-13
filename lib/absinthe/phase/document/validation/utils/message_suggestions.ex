defmodule Absinthe.Phase.Document.Validation.Utils.MessageSuggestions do
  @moduledoc false
  @default_maximum_number_of_suggestions 5

  @doc """
  Generate an suggestions message for a incorrect field
  """
  @spec suggest_message([String.t()], Absinthe.run_opts()) :: String.t()
  def suggest_message(suggestions, options) do
    maximum_number_of_suggestions = maximum_number_of_suggestions(options)

    if maximum_number_of_suggestions == 0 do
      ""
    else
      suggestions = Enum.take(suggestions, maximum_number_of_suggestions)
      " Did you mean " <> to_quoted_or_list(suggestions) <> "?"
    end
  end

  @spec suggest_fragment_message([String.t()], Absinthe.run_opts()) :: String.t()
  def suggest_fragment_message(suggestions, options) do
    maximum_number_of_suggestions = maximum_number_of_suggestions(options)

    if maximum_number_of_suggestions == 0 do
      ""
    else
      suggestions = Enum.take(suggestions, maximum_number_of_suggestions)

      " Did you mean to use an inline fragment on " <>
        to_quoted_or_list(suggestions) <> "?"
    end
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

  @spec maximum_number_of_suggestions(Absinthe.run_opts()) :: non_neg_integer()
  defp maximum_number_of_suggestions(options) do
    Keyword.get(options, :maximum_number_of_suggestions) || @default_maximum_number_of_suggestions
  end
end
