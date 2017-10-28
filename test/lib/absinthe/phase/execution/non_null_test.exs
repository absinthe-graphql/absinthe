defmodule Absinthe.Phase.Document.Execution.NonNullTest do
  use ExUnit.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    defp thing_resolver(_, %{make_null: make_null}, _) do
      if make_null do
        {:ok, nil}
      else
        {:ok, %{}}
      end
    end
    defp thing_resolver(_, _, _) do
      {:ok, %{}}
    end

    object :thing do
      field :nullable, :thing do
        arg :make_null, :boolean
        resolve &thing_resolver/3
      end

      @desc """
      A field declared to be non null.

      It accepts an argument for testing that can be used to make it return null,
      testing the null handling behaviour.
      """
      field :non_null, non_null(:thing) do
        arg :make_null, :boolean
        resolve &thing_resolver/3
      end

      field :non_null_error_field, non_null(:string) do
        resolve fn _, _ ->
          {:error, "boom"}
        end
      end
    end

    query do
      field :nullable, :thing do
        arg :make_null, :boolean
        resolve &thing_resolver/3
      end

      @desc """
      A field declared to be non null.

      It accepts an argument for testing that can be used to make it return null,
      testing the null handling behaviour.
      """
      field :non_null, non_null(:thing) do
        arg :make_null, :boolean
        resolve &thing_resolver/3
      end
    end
  end

  test "getting a null value normally works fine" do
    doc = """
    {
      nullable { nullable(makeNull: true) { __typename }}
    }
    """

    assert {:ok, %{data: %{"nullable" => %{"nullable" => nil}}}} == Absinthe.run(doc, Schema)
  end

  test "returning nil from a non null field makes the parent nullable null" do
    doc = """
    {
      nullable { nullable { nonNull(makeNull: true) { __typename }}}
    }
    """
    data = %{"nullable" => %{"nullable" => nil}}
    errors = [
      %{locations: [%{column: 0, line: 2}], message: "'Cannot return null for non-nullable field", path: ["nullable", "nullable", "nonNull"]},
    ]
    assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
  end

  test "returning an error from a non null field makes the parent nullable null" do
    doc = """
    {
      nullable { nullable { nonNullErrorField }}
    }
    """
    data = %{"nullable" => %{"nullable" => nil}}
    errors = [
      %{locations: [%{column: 0, line: 2}], message: "'Cannot return null for non-nullable field", path: ["nullable", "nullable", "nonNullErrorField"]},
      %{locations: [%{column: 0, line: 2}], message: "boom", path: ["nullable", "nullable", "nonNullErrorField"]}
    ]
    assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
  end

  test "returning an error from a non null field makes the parent nullable null at arbitrary depth" do
    doc = """
    {
      nullable { nonNull { nonNull { nonNull { nonNull { nonNullErrorField }}}}}
    }
    """
    data = %{"nullable" => nil}
    path = ["nullable", "nonNull", "nonNull", "nonNull", "nonNull", "nonNullErrorField"]
    errors = [
      %{locations: [%{column: 0, line: 2}], message: "'Cannot return null for non-nullable field", path: path},
      %{locations: [%{column: 0, line: 2}], message: "boom", path: path},
    ]
    assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
  end
end
