defmodule AssertResult do

  import ExUnit.Assertions

  def assert_result({lflag, lhs}, {rflag, rhs}) do
    assert clean(lhs) == clean(rhs)
    assert lflag == rflag
  end

  defp clean(%{errors: errors} = result) do
    cleaned = errors
    |> Enum.map(fn
      err ->
        Map.delete(err, :locations)
    end)
    %{result | errors: cleaned}
  end
  defp clean(result) do
    result
  end

end
