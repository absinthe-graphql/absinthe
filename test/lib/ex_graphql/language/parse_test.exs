defmodule ExGraphQL.Language.ParseTest do
  use ExUnit.Case

  test "returns a document" do
    assert {:ok, %{__struct__: ExGraphQL.Language.Document}} = ExGraphQL.parse("{ hello }")
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
    assert {:ok, doc} = ExGraphQL.parse(@mutation_with_alias)
  end

end
