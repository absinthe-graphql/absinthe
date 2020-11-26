defmodule Absinthe.Phase.Document.Execution.EscapeSequenceTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :echo, :string do
        arg :value, :string

        resolve(fn %{value: input_string}, _ ->
          {:ok, input_string}
        end)
      end
    end
  end

  test "one slash" do
    assert Absinthe.run(
             ~S"""
             {
               echo(value: "\FOO")
             }
             """,
             Schema
           ) == {:ok, %{data: %{"echo" => ~S"\FOO"}}}
  end

  test "two slashes" do
    assert Absinthe.run(
             ~S"""
             {
               echo(value: "\\FOO")
             }
             """,
             Schema
           ) == {:ok, %{data: %{"echo" => ~S"\FOO"}}}
  end

  test "four slashes" do
    assert Absinthe.run(
             ~S"""
             {
               echo(value: "\\\\FOO")
             }
             """,
             Schema
           ) == {:ok, %{data: %{"echo" => ~S"\\FOO"}}}
  end

  test "eight slashes" do
    assert Absinthe.run(
             ~S"""
             {
               echo(value: "\\\\\\\\FOO")
             }
             """,
             Schema
           ) == {:ok, %{data: %{"echo" => ~S"\\\\FOO"}}}
  end

  test "literal slash n" do
    assert Absinthe.run(
             ~S"""
             {
               echo(value: "\\nFOO")
             }
             """,
             Schema
           ) == {:ok, %{data: %{"echo" => ~S"\nFOO"}}}
  end
end
