defmodule Absinthe.Phase.Document.Execution.NonNullTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    defp thing_resolver(_, %{make_null: true, make_async: true}, _),
      do: async(fn -> {:ok, nil} end)

    defp thing_resolver(_, %{make_null: false, make_async: true}, _),
      do: async(fn -> {:ok, %{}} end)

    defp thing_resolver(_, %{make_null: true}, _),
      do: {:ok, nil}

    defp thing_resolver(_, _, _),
      do: {:ok, %{}}

    defp things_resolver(_, %{make_null: make_null}, _) do
      if make_null do
        {:ok, [nil]}
      else
        {:ok, [%{}]}
      end
    end

    defp things_resolver(_, _, _) do
      {:ok, [%{}]}
    end

    object :thing do
      field :nullable, :thing do
        arg :make_null, :boolean
        arg :make_async, :boolean
        resolve &thing_resolver/3
      end

      @desc """
      A field declared to be non null.

      It accepts an argument for testing that can be used to make it return null,
      testing the null handling behaviour.
      """
      field :non_null, non_null(:thing) do
        arg :make_null, :boolean
        arg :make_async, :boolean
        resolve &thing_resolver/3
      end

      field :non_null_error_field, non_null(:string) do
        resolve fn _, _ ->
          {:error, "boom"}
        end
      end

      field :async_non_null_error_field, non_null(:string) do
        resolve fn _, _ ->
          async(fn -> {:error, "boom"} end)
        end
      end

      field :non_null_list_of_non_null, non_null(list_of(non_null(:thing))) do
        arg :make_null, :boolean
        resolve &things_resolver/3
      end
    end

    query do
      field :nullable, :thing do
        arg :make_null, :boolean
        resolve &thing_resolver/3
      end

      field :non_null_error_field, non_null(:string) do
        resolve fn _, _ ->
          {:error, "boom"}
        end
      end

      field :async_non_null_error_field, non_null(:string) do
        resolve fn _, _ ->
          async(fn -> {:error, "boom"} end)
        end
      end

      field :nullable_list_of_nullable, list_of(:thing) do
        resolve &things_resolver/3
      end

      field :nullable_list_of_non_null, list_of(non_null(:thing)) do
        resolve &things_resolver/3
      end

      field :non_null_list_of_non_null, non_null(list_of(non_null(:thing))) do
        arg :make_null, :boolean
        resolve &things_resolver/3
      end

      field :async_nullable_list_of_nullable, list_of(:thing) do
        resolve fn _, _ ->
          async(fn -> {:ok, [%{}]} end)
        end
      end

      field :async_nullable_list_of_non_null, list_of(non_null(:thing)) do
        resolve fn _, _ ->
          async(fn -> {:ok, [%{}]} end)
        end
      end

      field :async_non_null_list_of_non_null, non_null(list_of(non_null(:thing))) do
        resolve fn _, _ ->
          async(fn -> {:ok, [%{}]} end)
        end
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

  describe "synchronous" do
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
        %{
          locations: [%{column: 25, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["nullable", "nullable", "nonNull"]
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end

    test "returning nil from a non null child of non nulls pushes nil all the way up to data" do
      doc = """
      {
        nonNull { nonNull { nonNull(makeNull: true) { __typename }}}
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

    test "error propagation to root field returns nil on data" do
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

    test "returning an error from a non null field makes the parent nullable null" do
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
  end

  describe "asynchronous" do
    test "getting a null value normally works fine" do
      doc = """
      {
        nullable { nullable(makeNull: true, makeAsync: true) { __typename }}
      }
      """

      assert {:ok, %{data: %{"nullable" => %{"nullable" => nil}}}} == Absinthe.run(doc, Schema)
    end

    test "returning nil from a non null field makes the parent nullable null" do
      doc = """
      {
        nullable { nullable { nonNull(makeNull: true, makeAsync: true) { __typename }}}
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

    test "returning nil from a non null child of non nulls pushes nil all the way up to data" do
      doc = """
      {
        nonNull { nonNull { nonNull(makeNull: true, makeAsync: true) { __typename }}}
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

    test "error propagation to root field returns nil on data" do
      doc = """
      {
        nullable { nullable { asyncNonNullErrorField }}
      }
      """

      data = %{"nullable" => %{"nullable" => nil}}

      errors = [
        %{
          locations: [%{column: 25, line: 2}],
          message: "boom",
          path: ["nullable", "nullable", "asyncNonNullErrorField"]
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end

    test "returning an error from a non null field makes the parent nullable null" do
      doc = """
      {
        nonNull { nonNull { asyncNonNullErrorField }}
      }
      """

      result = Absinthe.run(doc, Schema)

      errors = [
        %{
          locations: [%{column: 23, line: 2}],
          message: "boom",
          path: ["nonNull", "nonNull", "asyncNonNullErrorField"]
        }
      ]

      assert {:ok, %{data: nil, errors: errors}} == result
    end

    test "returning an error from a non null field makes the parent nullable null at arbitrary depth" do
      doc = """
      {
        nullable { nonNull { nonNull { nonNull { nonNull { asyncNonNullErrorField }}}}}
      }
      """

      data = %{"nullable" => nil}
      path = ["nullable", "nonNull", "nonNull", "nonNull", "nonNull", "asyncNonNullErrorField"]

      errors = [
        %{locations: [%{column: 54, line: 2}], message: "boom", path: path}
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end
  end

  describe "lists" do
    test "list of nullable things works when child has a null violation" do
      doc = """
      {
        nullableListOfNullable { nonNull(makeNull: true) { __typename } }
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

    test "list of non null things works when child has a null violation" do
      doc = """
      {
        nullableListOfNonNull { nonNull(makeNull: true) { __typename } }
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

    test "list of non null things works when child has a null violation and the root field is non null" do
      doc = """
      {
        nonNullListOfNonNull { nonNull(makeNull: true) { __typename } }
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

    test "list of non null things works when child is null" do
      doc = """
      {
        nonNullListOfNonNull(makeNull: true) { __typename }
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
                nonNullListOfNonNull(makeNull: true) { __typename }
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

  describe "async lists" do
    test "list of nullable things works when child has a null violation" do
      doc = """
      {
        asyncNullableListOfNullable { nonNull(makeNull: true) { __typename } }
      }
      """

      data = %{"asyncNullableListOfNullable" => [nil]}

      errors = [
        %{
          locations: [%{column: 33, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["asyncNullableListOfNullable", 0, "nonNull"]
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end

    test "list of non null things works when child has a null violation" do
      doc = """
      {
        asyncNullableListOfNonNull { nonNull(makeNull: true) { __typename } }
      }
      """

      data = %{"asyncNullableListOfNonNull" => nil}

      errors = [
        %{
          locations: [%{column: 32, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["asyncNullableListOfNonNull", 0, "nonNull"]
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end

    test "list of non null things works when child has a null violation and the root field is non null" do
      doc = """
      {
        asyncNonNullListOfNonNull { nonNull(makeNull: true) { __typename } }
      }
      """

      data = nil

      errors = [
        %{
          locations: [%{column: 31, line: 2}],
          message: "Cannot return null for non-nullable field",
          path: ["asyncNonNullListOfNonNull", 0, "nonNull"]
        }
      ]

      assert {:ok, %{data: data, errors: errors}} == Absinthe.run(doc, Schema)
    end
  end
end
