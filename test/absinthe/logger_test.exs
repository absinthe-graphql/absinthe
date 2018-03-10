defmodule Absinthe.LoggerTest do
  use Absinthe.Case, async: true

  describe "Absinthe.Logger.filter_variables/1" do
    @value "abcd"
    @variables %{"token" => @value, "password" => @value, "alsoUnsafe" => @value}
    @filtered "[FILTERED]"

    test "it filters the set values, with defaults" do
      assert %{
               "token" => @filtered,
               "password" => @filtered,
               "alsoUnsafe" => @value
             } = Absinthe.Logger.filter_variables(@variables)
    end

    test "it filters given values" do
      assert %{
               "token" => @filtered,
               "password" => @value,
               "alsoUnsafe" => @filtered
             } = Absinthe.Logger.filter_variables(@variables, ~w(token alsoUnsafe))
    end
  end

  describe "Absinthe.Logger.document/1" do
    @document nil
    test "given nil, is [EMPTY]" do
      assert "[EMPTY]" = Absinthe.Logger.document(@document)
    end

    @document ""
    test "given an empty string, is also [EMPTY]" do
      assert "[EMPTY]" = Absinthe.Logger.document(@document)
    end

    @document "{ foo }"
    test "given a non-empty string, is the document with a leading newline" do
      assert @document == Absinthe.Logger.document(@document)
    end

    @document %Absinthe.Blueprint{name: "name"}
    test "given a blueprint document with a name, is [COMPILED#<name>]" do
      assert "[COMPILED#<name>]" == Absinthe.Logger.document(@document)
    end

    @document %Absinthe.Blueprint{}
    test "given a blueprint document without a name, is [COMPILED]" do
      assert "[COMPILED]" == Absinthe.Logger.document(@document)
    end

    @document %{}
    test "given something else, is inspected" do
      assert "%{}" == Absinthe.Logger.document(@document)
    end
  end
end
