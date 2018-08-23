defmodule Absinthe.Phase.Parse.DescriptionsTest do
  use Absinthe.Case, async: true

  @moduletag :parser
  @moduletag :sdl

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
    assert {:ok,
            %{
              definitions: [
                %Absinthe.Language.ObjectTypeDefinition{
                  description: "A simple GraphQL schema which is well described.",
                  fields: [
                    %Absinthe.Language.FieldDefinition{
                      arguments: [
                        %Absinthe.Language.InputValueDefinition{
                          description: "The original language that `text` is provided in."
                        },
                        %Absinthe.Language.InputValueDefinition{
                          description: "The translated language to be returned."
                        },
                        %Absinthe.Language.InputValueDefinition{
                          description: "The text to be translated."
                        }
                      ],
                      description:
                        "Translates a string from a given language into a different language."
                    }
                  ]
                },
                %Absinthe.Language.EnumTypeDefinition{
                  description: "The set of languages supported by `translate`.",
                  values: [
                    %Absinthe.Language.EnumValueDefinition{
                      description: "English"
                    },
                    %Absinthe.Language.EnumValueDefinition{
                      description: "French"
                    },
                    %Absinthe.Language.EnumValueDefinition{
                      description: "Chinese"
                    }
                  ]
                }
              ]
            }} = run(@sdl)
  end

  def run(input) do
    with {:ok, %{input: input}} <- Absinthe.Phase.Parse.run(input) do
      {:ok, input}
    end
  end
end
