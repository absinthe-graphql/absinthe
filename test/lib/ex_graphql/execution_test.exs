defmodule ExGraphQL.ExecutionTest do
  use ExSpec, async: true

  alias ExGraphQL.Execution

  @document """
  query DroidFieldInFragment {
    hero {
      name
      ...DroidFields
    }
  }

  fragment DroidFields on Droid {
    primaryFunction
  }
  """

  it "categorize_definitions fragments and operation definitions" do
    document = ExGraphQL.parse!(@document)
    execution = %ExGraphQL.Execution{document: document}
    |> ExGraphQL.Execution.categorize_definitions
    assert execution.fragments |> Map.get("DroidFields")
    assert execution.operations |> Map.get("DroidFieldInFragment")

    assert execution.fragments |> Map.size == 1
    assert execution.operations |> Map.size == 1
  end

  it "doesn't currently validate" do
    document = ExGraphQL.parse!(@document)
    assert {:error, _} = %Execution{document: document, validate: true} |> Execution.validate
    assert {:ok, _} = %Execution{document: document, validate: false} |> Execution.validate
  end

  it "can select the correct operation when multiple are available" do
    schema = StarWars.Schema.schema
    query = """
      query HeroNameQuery {
        hero {
          name
        }
      }
      query HeroFriendsQuery {
        hero {
          friends {
            name
          }
        }
      }
    """
    document = ExGraphQL.parse!(query)

    # Name provided
    execution = %Execution{schema: schema, document: document, operation_name: "HeroNameQuery"}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    assert {:ok, _} = execution

    # Name not provided
    execution = %Execution{schema: schema, document: document}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    assert {:error, _} = execution

  end

  it "can select the correct operation when one is available" do
    schema = StarWars.Schema.schema
    query = """
      query HeroNameQuery {
        hero {
          name
        }
      }
    """
    document = ExGraphQL.parse!(query)

    # Name provided
    execution = %Execution{schema: schema, document: document, operation_name: "HeroNameQuery"}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    assert {:ok, _} = execution

    # Wrong name
    execution = %Execution{schema: schema, document: document, operation_name: "NotExisting"}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    assert {:error, _} = execution

    # Name not provided
    execution = %Execution{schema: schema, document: document}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    assert {:ok, _} = execution

  end

  it "can select the correct operation when none is available" do
    schema = StarWars.Schema.schema
    query = ""
    document = ExGraphQL.parse!(query)

    # Wrong name
    execution = %Execution{schema: schema, document: document, operation_name: "NotExisting"}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    assert {:error, _} = execution

    # None
    execution = %Execution{schema: schema, document: document}
    |> Execution.categorize_definitions
    |> Execution.selected_operation
    assert {:ok, nil} = execution

  end

end
