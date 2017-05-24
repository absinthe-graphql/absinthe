defmodule Absinthe.LoggerTest do
  use Absinthe.Case, async: true

  context "Absinthe.Logger.filter_variables/1" do
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

  context "Absinthe.Logger.document/1" do

    context "given nil" do
      @document nil
      test "is [EMPTY]" do
        assert "[EMPTY]" = Absinthe.Logger.document(@document)
      end
    end

    context "given an empty string" do
      @document ""
      test "is alse [EMPTY]" do
        assert "[EMPTY]" = Absinthe.Logger.document(@document)
      end
    end

    context "given a non-empty string" do
      @document "{ foo }"
      test "is the document with a leading newline" do
        assert @document == Absinthe.Logger.document(@document)
      end
    end

    context "given a blueprint document with a name" do
      @document %Absinthe.Blueprint{name: "name"}
      test "is [COMPILED#<name>]" do
        assert "[COMPILED#<name>]" == Absinthe.Logger.document(@document)
      end
    end

    context "given a blueprint document without a name" do
      @document %Absinthe.Blueprint{}
      test "is [COMPILED]" do
        assert "[COMPILED]" == Absinthe.Logger.document(@document)
      end
    end

    context "given something else" do
      @document %{}
      test "is inspected" do
        assert "%{}" == Absinthe.Logger.document(@document)
      end
    end

  end

end
