defmodule Absinthe.Phase.Schema.CoordinatesTest do
  use Absinthe.Case, async: true

  import Absinthe.Blueprint.Schema, only: [lookup_type: 2]

  alias Absinthe.Phase.Schema.Coordinates

  defmodule Schema do
    use Absinthe.Schema

    enum :age_demographic do
      value :child
      value :young_adult
      value :adult
    end

    enum :status do
      value :living
      value :not_living
    end

    object :human_user do
      field :family_name, :string
      field :surname, :string
      field :age_demographic, :age_demographic
      field :status, :status
    end

    input_object :name_input do
      field :family_name, :string
      field :surname, :string
    end

    input_object :by do
      field :name, :name_input do
        arg(:living, :boolean)
        arg(:not_living, :boolean)
      end
    end

    query do
      field :get_user, :human_user do
        arg(:by, :by)
        arg(:include_deceased, :boolean)
      end
    end
  end

  setup_all do
    {:ok, blueprint} = Coordinates.run(Schema.__absinthe_blueprint__())
    [blueprint: blueprint]
  end

  describe "run/2 for object types" do
    test "schema", %{blueprint: %{schema_definitions: [schema_definition]}} do
      assert %{coordinate: "Schema"} = schema_definition
    end

    test "single word", %{blueprint: blueprint} do
      assert %{coordinate: "RootQueryType"} = lookup_type(blueprint, :query)
    end

    test "multiple words", %{blueprint: blueprint} do
      assert %{coordinate: "HumanUser"} = lookup_type(blueprint, :human_user)
    end
  end

  describe "run/2 for input types" do
    test "single word", %{blueprint: blueprint} do
      assert %{coordinate: "By"} = lookup_type(blueprint, :by)
    end

    test "multiple words", %{blueprint: blueprint} do
      assert %{coordinate: "NameInput"} = lookup_type(blueprint, :name_input)
    end
  end

  describe "run/2 for enum types" do
    test "single word", %{blueprint: blueprint} do
      assert %{coordinate: "Status"} = lookup_type(blueprint, :status)
    end

    test "multiple words", %{blueprint: blueprint} do
      assert %{coordinate: "AgeDemographic"} = lookup_type(blueprint, :age_demographic)
    end
  end

  describe "run/2 for enum values" do
    test "single word", %{blueprint: blueprint} do
      assert %{coordinate: "AgeDemographic.CHILD"} =
               lookup_enum_value(blueprint, :age_demographic, :child)
    end

    test "multiple words", %{blueprint: blueprint} do
      assert %{coordinate: "AgeDemographic.YOUNG_ADULT"} =
               lookup_enum_value(blueprint, :age_demographic, :young_adult)
    end
  end

  describe "run/2 for fields" do
    test "top level field", %{blueprint: blueprint} do
      assert %{coordinate: "RootQueryType.getUser"} = lookup_field(blueprint, :query, :get_user)
    end

    test "single words", %{blueprint: blueprint} do
      assert %{coordinate: "HumanUser.surname"} =
               lookup_field(blueprint, :human_user, :surname)
    end

    test "multiple words", %{blueprint: blueprint} do
      assert %{coordinate: "HumanUser.familyName"} =
               lookup_field(blueprint, :human_user, :family_name)
    end

    test "single word on input type", %{blueprint: blueprint} do
      assert %{coordinate: "NameInput.surname"} = lookup_field(blueprint, :name_input, :surname)
    end

    test "multiple words on input type", %{blueprint: blueprint} do
      assert %{coordinate: "NameInput.familyName"} =
               lookup_field(blueprint, :name_input, :family_name)
    end
  end

  describe "run/2 for arguments" do
    test "single word", %{blueprint: blueprint} do
      assert %{coordinate: "RootQueryType.getUser(by:)"} =
               lookup_argument(blueprint, :query, :get_user, :by)
    end

    test "multiple words", %{blueprint: blueprint} do
      assert %{coordinate: "RootQueryType.getUser(includeDeceased:)"} =
               lookup_argument(blueprint, :query, :get_user, :include_deceased)
    end

    test "single word on input field", %{blueprint: blueprint} do
      assert %{coordinate: "By.name(living:)"} = lookup_argument(blueprint, :by, :name, :living)
    end

    test "multiple words on input field", %{blueprint: blueprint} do
      assert %{coordinate: "By.name(notLiving:)"} =
               lookup_argument(blueprint, :by, :name, :not_living)
    end
  end

  defp lookup_field(blueprint, type, field) do
    blueprint
    |> lookup_type(type)
    |> Map.get(:fields)
    |> Enum.find(&(&1.identifier == field))
  end

  defp lookup_argument(blueprint, type, field, argument) do
    blueprint
    |> lookup_field(type, field)
    |> Map.get(:arguments)
    |> Enum.find(&(&1.identifier == argument))
  end

  defp lookup_enum_value(blueprint, enum, value) do
    blueprint
    |> lookup_type(enum)
    |> Map.get(:values)
    |> Enum.find(&(&1.identifier == value))
  end
end
