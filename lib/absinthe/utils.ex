defmodule Absinthe.Utils do

  @doc """
  Camelize a word, but with a lowercase first letter.

  ## Examples

  ```
  iex> camelize_lower("foo_bar")
  "fooBar"
  iex> camelize_lower("foo")
  "foo"
  ```
  """
  @spec camelize_lower(binary) :: binary
  def camelize_lower(word) do
    {first, rest} = String.split_at(Macro.camelize(word), 1)
    String.upcase(first) <> rest
  end

end
