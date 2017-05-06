defmodule Absinthe.Phase.Document.VariablesTest do
  use ExUnit.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :echo, :string do
        arg :input, :string

        resolve fn %{input: input}, _ ->
          {:ok, input}
        end
      end
    end
  end

  test "we can go all the way through the validations without errors" do
    doc = """
    query Echo($input: String) {
      echo(input: $input)
    }
    """

    assert {:ok, _blueprint, _} = validate(doc)
  end

  test "documents with variable values that are the wrong type for the field still error" do
    doc = """
    query Echo($input: Int) {
      echo(input: $input)
    }
    """

    assert {:error, _blueprint, _} = validate(doc)
  end

  defp validate(doc) do
    pipeline =
      Schema
      |> Absinthe.Pipeline.for_document(jump_phases: false)
      |> Absinthe.Pipeline.upto(Absinthe.Phase.Document.Validation.Result)

    Absinthe.Pipeline.run(doc, pipeline)
  end
end
