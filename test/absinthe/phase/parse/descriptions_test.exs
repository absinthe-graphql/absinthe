defmodule Absinthe.Phase.Parse.DescriptionsTest do
  use Absinthe.Case, async: true

  @moduletag :parser

  @sdl """
  \"""
  A simple GraphQL schema which is well described.
  \"""
  type Query {
    \"""
    Translates a string from a given language into a different language.
    \"""
    translate(
      "The original language that `text` is provided in."
      fromLanguage: Language
  
      "The translated language to be returned."
      toLanguage: Language
  
      "The text to be translated."
      text: String
    ): String
  }
  
  \"""
  The set of languages supported by `translate`.
  \"""
  enum Language {
    "English"
    EN
  
    "French"
    FR
  
    "Chinese"
    CH
  }  
  """

  test "parses descriptions" do
    \"""
    Foo
    \"""
    type Mine {
      \"""
      Another
      \"""
      foos: [Foo!]
    }
    """))
    assert {:ok, result} = run(@sdl)
  end

  def run(input) do
    with {:ok, %{input: input}} <- Absinthe.Phase.Parse.run(input) do
      {:ok, input}
    end
  end

end
