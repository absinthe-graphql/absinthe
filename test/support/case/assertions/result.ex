defmodule Absinthe.Case.Assertions.Result do
  import ExUnit.Assertions

  def assert_result({lflag, lhs}, {rflag, rhs}) do
    assert clean(lhs) == clean(rhs)
    assert lflag == rflag
  end

  def assert_data(expected, result) do
    assert_result({:ok, %{data: expected}}, result)
  end

  def assert_error_message_lines(lines, result) do
    assert_error_message(Enum.join(lines, "\n"), result)
  end

  # Dialyzer often has issues with test code, and here it says that
  # the assertion on line 20 can never match, which is silly.
  @dialyzer {:no_match, assert_error_message: 2}
  def assert_error_message(error_message, result) do
    assert {:ok, %{errors: errors}} = result

    assert Enum.any?(errors, fn %{message: message} ->
             message == error_message
           end)
  end

  defp clean(%{errors: errors} = result) do
    cleaned =
      errors
      |> Enum.map(fn err ->
        Map.delete(err, :locations)
      end)

    %{result | errors: cleaned}
  end

  defp clean(result) do
    result
  end
end
