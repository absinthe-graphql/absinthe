defmodule Absinthe.Language.ParseTest do
  use ExUnit.Case

  test "returns a document" do
    assert {:ok, %{__struct__: Absinthe.Language.Document}} = Absinthe.parse("{ hello }")
  end

  @mutation_with_alias """
  mutation ProvisionTopicsAndQueues {
    queue1: createQueue(name: "new-queue1") {
      url
    }
    queue2: createQueue(name: "new-queue2") {
      url
    }
    topic1: createTopic(name: "new-topic1") {
      arn
    }
    topic2: createTopic(name: "new-topic2") {
      arn
    }
    topic3: createTopic(name: "new-topic3") {
      arn
    }
  }
  """

  test "can parse a mutation with an alias" do
    assert {:ok, _} = Absinthe.parse(@mutation_with_alias)
  end

  @nested_input """
  mutation CreateSession {
    createSession(contact: {value: "5551212"}, token: "124125124jlkj12") {
      token
      user {
        id
        name
      }
    }
  }
  """
  test "can parse a mutation with a complex input" do
    assert {:ok, _} = Absinthe.parse(@nested_input)
  end

end
