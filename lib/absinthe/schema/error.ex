defmodule Absinthe.Schema.Error do
  @moduledoc """
  Exception raised when a schema is invalid
  """
  defexception message: "Invalid schema"

  @titles %{
    dup_ident: "Duplicate type identifier",
    dup_nam: "Duplicate type name"
  }

  def exception(problems) do
    detail = Enum.map(problems, &format_problem/1) |> Enum.join("\n")
    %__MODULE__{message: "Invalid schema:\n" <> detail <> "\n"}
  end

  def format_problem(problem) do
    "#{problem.location.file}:#{problem.location.line}: #{@titles[problem.name]} #{inspect(problem.data)}"
  end

end
