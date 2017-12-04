defmodule Absinthe.Phase.Parse.BlockStringsTest do
  use Absinthe.Case, async: true

  it "parses a query with a block string argument literal and no newlines" do
    assert {:ok, _} = run(~s<{ post(title: "single", body: """text""") { name } }>)
  end

  it "parses a query with a block string argument literal and newlines" do
    assert {:ok, _} = run(
      ~s<{ post(title: "single", body: """
             text
      """) { name } }>)
  end


  def run(input) do
    with {:ok, %{input: input}} <- Absinthe.Phase.Parse.run(input) do
      {:ok, input}
    end
  end

end
