defmodule Absinthe.Phase.Document.Execution.NonNullTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    defp thing_resolver(_, %{return_null: return_null}, _) do
      if return_null do
        {:ok, nil}
      else
        {:ok, %{}}
      end
    end

    defp thing_resolver(_, _, _) do
      {:ok, %{}}
    end

    defp things_resolver(_, %{return_null_element: return_null_element}, _) do
      if return_null_element do
        {:ok, [nil]}
      else
        {:ok, [%{}]}
      end
    end

    defp things_resolver(_, %{return_null: return_null}, _) do
      if return_null do
        {:ok, nil}
      else
        {:ok, [%{}]}
      end
    end

    defp things_resolver(_, _, _) do
      {:ok, [%{}]}
    end

    object :thing do
      field :nullable, :thing do
        arg :return_null, :boolean
        resolve &thing_resolver/3
      end

      @desc """
      A field declared to be non null.

      It accepts an argument for testing that can be used to make it return null,
      testing the null handling behaviour.
      """
      field :non_null, non_null(:thing) do
        arg :return_null, :boolean
        resolve &thing_resolver/3
      end

      field :non_null_error_field, non_null(:string) do
        resolve fn _, _ ->
          {:error, "boom"}
        end
      end

      field :non_null_list_of_non_null, non_null(list_of(non_null(:thing))) do
        arg :return_null_element, :boolean
        resolve &things_resolver/3
      end
    end

    query do
      field :nullable, :thing do
        arg :return_null, :boolean
        resolve &thing_resolver/3
      end

      field :non_null_error_field, non_null(:string) do
        resolve fn _, _ ->
          {:error, "boom"}
        end
      end

      field :nullable_list_of_nullable, list_of(:thing) do
        resolve &things_resolver/3
      end

      field :nullable_list_of_non_null, list_of(non_null(:thing)) do
        resolve &things_resolver/3
      end

      field :non_null_list_of_non_null, non_null(list_of(non_null(:thing))) do
        arg :return_null_element, :boolean
        resolve &things_resolver/3
      end

      field :non_null_list_of_nullable, non_null(list_of(:thing)) do
        arg :return_null, :boolean
        arg :return_null_element, :boolean
        resolve &things_resolver/3
      end

      field :non_null_list_of_non_null_list_of_nullable,
            non_null(list_of(non_null(list_of(:string)))) do
        resolve fn _, _ ->
          {:ok, [["ok", nil]]}
        end
      end

      field :deeply_nested_non_nullable_list_of_nullable,
            non_null(list_of(non_null(list_of(non_null(list_of(non_null(list_of(:string)))))))) do
        resolve fn _, _ ->
          {:ok, [[[["ok", nil]]]]}
        end
      end

      field :deeply_nested_non_nullable_list_of_non_nullable,
            non_null(
              list_of(non_null(list_of(non_null(list_of(non_null(list_of(non_null(:string))))))))
            ) do
        resolve fn _, _ ->
          {:ok, [[[["1", nil, "3"], ["4", nil, "6"]]]]}
        end
      end

      @desc """
      A field declared to be non null.

      It accepts an argument for testing that can be used to make it return null,
      testing the null handling behaviour.
      """
      field :non_null, non_null(:thing) do
        arg :return_null, :boolean
        resolve &thing_resolver/3
      end
    end
  end

  test "getting a null value normally works fine" do
    doc = """
    {
      nullable { nullable(returnNull: true) { __typename }}
    }
    """

    assert {:ok, %{data: %{"nullable" => %{"nullable" => nil}}}} == Absinthe.run(doc, Schema)
  end

  test "returning nil from a non null field returns an error and makes the parent nullable null" do
    doc = """
    {
      nullable { nullable { nonNull(returnNull: true) { __typename }}}
    }
    """

    data = %{"nullable" => %{"nullable" => nil}}

    errors = [
      %{
        locations: [%{column: 25, line: 2}],
        message: "Cannot return null for non-nullable field",
        path: ["nullable", "nullable", "nonNull"]
      }
    ]

    assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
  end

  test "returning nil from a non null child of non nulls returns an error and pushes nil all the way up to data" do
    doc = """
    {
      nonNull { nonNull { nonNull(returnNull: true) { __typename }}}
    }
    """

    data = nil

    errors = [
      %{
        locations: [%{column: 23, line: 2}],
        message: "Cannot return null for non-nullable field",
        path: ["nonNull", "nonNull", "nonNull"]
      }
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
      %{
        locations: [%{column: 25, line: 2}],
        message: "boom",
        path: ["nullable", "nullable", "nonNullErrorField"]
      }
    ]

    assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
  end

  test "error propagation to root field returns nil on data" do
    doc = """
    {
      nonNull { nonNull { nonNullErrorField }}
    }
    """

    result = Absinthe.run(doc, Schema)

    errors = [
      %{
        locations: [%{column: 23, line: 2}],
        message: "boom",
        path: ["nonNull", "nonNull", "nonNullErrorField"]
      }
    ]

    assert {:ok, %{data: nil, errors: errors}} == result
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
      %{locations: [%{column: 54, line: 2}], message: "boom", path: path}
    ]

    assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
  end

  describe "lists" do
    test "non-null list of non-null list of nullable value returns null value" do
      doc = """
      {
        nonNullListOfNonNullListOfNullable
      }
      """

      assert {:ok, %{data: %{"nonNullListOfNonNullListOfNullable" => [["ok", nil]]}}} ==
               Absinthe.run(doc, Schema)
    end

    test "deeply nested nullable value inside non-nullable lists can be null" do
      doc = """
      {
        deeplyNestedNonNullableListOfNullable
      }
      """

      assert {:ok, %{data: %{"deeplyNestedNonNullableListOfNullable" => [[[["ok", nil]]]]}}} ==
               Absinthe.run(doc, Schema)
    end

    test "deeply nested non-nullable value inside non-nullable lists cannot be null" do
      doc = """
      {
        deeplyNestedNonNullableListOfNonNullable
      }
      """

      errors = [
        %{
          locations: [%{column: 3, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["deeplyNestedNonNullableListOfNonNullable", 0, 0, 0, 1]
        },
        %{
          locations: [%{column: 3, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["deeplyNestedNonNullableListOfNonNullable", 0, 0, 1, 1]
        }
      ]

      assert {:ok, %{data: nil, errors: errors}} == Absinthe.run(doc, Schema)
    end

    test "list of nullable things returns an error when child has a null violation" do
      doc = """
      {
        nullableListOfNullable { nonNull(returnNull: true) { __typename } }
      }
      """

      data = %{"nullableListOfNullable" => [nil]}

      errors = [
        %{
          locations: [%{column: 28, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["nullableListOfNullable", 0, "nonNull"]
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end

    test "list of non null things returns an error when child has a null violation" do
      doc = """
      {
        nullableListOfNonNull { nonNull(returnNull: true) { __typename } }
      }
      """

      data = %{"nullableListOfNonNull" => nil}

      errors = [
        %{
          locations: [%{column: 27, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["nullableListOfNonNull", 0, "nonNull"]
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end

    test "list of non null things returns an error when child has a null violation and the root field is non null" do
      doc = """
      {
        nonNullListOfNonNull { nonNull(returnNull: true) { __typename } }
      }
      """

      data = nil

      errors = [
        %{
          locations: [%{column: 26, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["nonNullListOfNonNull", 0, "nonNull"]
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end

    test "non null list of nullable returns an error when null" do
      doc = """
      {
        nonNullListOfNullable(returnNull: true) { __typename }
      }
      """

      data = nil

      errors = [
        %{
          locations: [%{column: 3, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["nonNullListOfNullable"]
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end

    test "non null list of nullable allows returning a list with null elements" do
      doc = """
      {
        nonNullListOfNullable(returnNullElement: true) { __typename }
      }
      """

      data = %{"nonNullListOfNullable" => [nil]}

      assert {:ok, %{data: data}} == Absinthe.run(doc, Schema)
    end

    test "list of non null things returns an error when child is null" do
      doc = """
      {
        nonNullListOfNonNull(returnNullElement: true) { __typename }
      }
      """

      data = nil

      errors = [
        %{
          locations: [%{column: 3, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["nonNullListOfNonNull", 0]
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end

    test "returning null from a non null list makes the parent nullable null at arbitrary depth" do
      doc = """
      {
        nullableListOfNonNull {
          nonNullListOfNonNull {
            nonNullListOfNonNull {
              nonNullListOfNonNull {
                nonNullListOfNonNull(returnNullElement: true) { __typename }
              }
            }
          }
        }
      }
      """

      data = %{"nullableListOfNonNull" => nil}

      path = [
        "nullableListOfNonNull",
        0,
        "nonNullListOfNonNull",
        0,
        "nonNullListOfNonNull",
        0,
        "nonNullListOfNonNull",
        0,
        "nonNullListOfNonNull",
        0
      ]

      errors = [
        %{
          locations: [%{column: 11, line: 6}],
          message: "Cannot return null for non-nullable field",
          path: path
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end
  end
end
