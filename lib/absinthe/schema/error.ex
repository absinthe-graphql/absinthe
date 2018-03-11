defmodule Absinthe.Schema.Error do
  @moduledoc """
  Exception raised when a schema is invalid
  """
  defexception message: "Invalid schema", details: []

  @type detail_t :: %{
          rule: Absinthe.Schema.Rule.t(),
          location: %{file: binary, line: integer},
          data: any
        }

  def exception(details) do
    detail = Enum.map(details, &format_detail/1) |> Enum.join("\n")
    %__MODULE__{message: "Invalid schema:\n" <> detail <> "\n", details: details}
  end

  def format_detail(detail) do
    explanation = indent(detail.rule.explanation(detail))
    "#{detail.location.file}:#{detail.location.line}: #{explanation}\n"
  end

  defp indent(text) do
    text
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&"  #{&1}")
    |> Enum.join("\n")
    |> String.trim_leading()
  end
end
