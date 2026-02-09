defmodule Absinthe.Schema.CoordinateTest do
  use Absinthe.Case, async: true

  alias Absinthe.Schema.Coordinate

  # Test schema for resolution tests
  defmodule TestSchema do
    use Absinthe.Schema

    enum :status do
      value :active
      value :inactive
      value :pending
    end

    input_object :create_user_input do
      field :name, non_null(:string)
      field :email, non_null(:string)
      field :status, :status
    end

    object :user do
      field :id, non_null(:id)
      field :name, :string
      field :email, :string
      field :status, :status

      field :posts, list_of(:post) do
        arg :limit, :integer
        arg :offset, :integer
      end
    end

    object :post do
      field :id, non_null(:id)
      field :title, :string
      field :body, :string
    end

    query do
      field :user, :user do
        arg :id, non_null(:id)
      end

      field :users, list_of(:user) do
        arg :status, :status
        arg :limit, :integer, default_value: 10
      end
    end

    mutation do
      field :create_user, :user do
        arg :input, non_null(:create_user_input)
      end
    end
  end

  describe "coordinate generation" do
    test "for_type/1 generates type coordinates" do
      assert Coordinate.for_type("User") == "User"
      assert Coordinate.for_type(:user) == "user"
    end

    test "for_field/2 generates field coordinates" do
      assert Coordinate.for_field("User", "email") == "User.email"
      assert Coordinate.for_field("Query", "user") == "Query.user"
    end

    test "for_argument/3 generates argument coordinates" do
      assert Coordinate.for_argument("Query", "user", "id") == "Query.user(id:)"
      assert Coordinate.for_argument("User", "posts", "limit") == "User.posts(limit:)"
    end

    test "for_enum_value/2 generates enum value coordinates" do
      assert Coordinate.for_enum_value("Status", "ACTIVE") == "Status.ACTIVE"
    end

    test "for_input_field/2 generates input field coordinates" do
      assert Coordinate.for_input_field("CreateUserInput", "email") == "CreateUserInput.email"
    end

    test "for_directive/1 generates directive coordinates" do
      assert Coordinate.for_directive("deprecated") == "@deprecated"
      assert Coordinate.for_directive("@skip") == "@skip"
    end

    test "for_directive_argument/2 generates directive argument coordinates" do
      assert Coordinate.for_directive_argument("deprecated", "reason") == "@deprecated(reason:)"
      assert Coordinate.for_directive_argument("@include", "if") == "@include(if:)"
    end
  end

  describe "coordinate parsing" do
    test "parse/1 parses type coordinates" do
      assert Coordinate.parse("User") == {:ok, {:type, "User"}}
      assert Coordinate.parse("Query") == {:ok, {:type, "Query"}}
      assert Coordinate.parse("__Type") == {:ok, {:type, "__Type"}}
    end

    test "parse/1 parses field coordinates" do
      assert Coordinate.parse("User.email") == {:ok, {:field, "User", "email"}}
      assert Coordinate.parse("Query.user") == {:ok, {:field, "Query", "user"}}
    end

    test "parse/1 parses argument coordinates" do
      assert Coordinate.parse("Query.user(id:)") == {:ok, {:argument, "Query", "user", "id"}}
      assert Coordinate.parse("User.posts(limit:)") == {:ok, {:argument, "User", "posts", "limit"}}
    end

    test "parse/1 parses directive coordinates" do
      assert Coordinate.parse("@deprecated") == {:ok, {:directive, "deprecated"}}
      assert Coordinate.parse("@skip") == {:ok, {:directive, "skip"}}
    end

    test "parse/1 parses directive argument coordinates" do
      assert Coordinate.parse("@deprecated(reason:)") == {:ok, {:directive_argument, "deprecated", "reason"}}
      assert Coordinate.parse("@include(if:)") == {:ok, {:directive_argument, "include", "if"}}
    end

    test "parse/1 returns error for invalid coordinates" do
      assert {:error, _} = Coordinate.parse("")
      assert {:error, _} = Coordinate.parse("invalid coordinate!")
      assert {:error, _} = Coordinate.parse("User.field.nested")
      assert {:error, _} = Coordinate.parse("@@double")
    end

    test "parse/1 handles whitespace" do
      assert Coordinate.parse("  User  ") == {:ok, {:type, "User"}}
      assert Coordinate.parse(" User.email ") == {:ok, {:field, "User", "email"}}
    end

    test "parse!/1 raises on invalid coordinate" do
      assert_raise ArgumentError, fn ->
        Coordinate.parse!("invalid!")
      end
    end

    test "parse!/1 returns parsed coordinate on success" do
      assert Coordinate.parse!("User.email") == {:field, "User", "email"}
    end
  end

  describe "coordinate resolution" do
    test "resolve/2 resolves type coordinates" do
      assert {:ok, type} = Coordinate.resolve(TestSchema, "User")
      assert type.identifier == :user
    end

    test "resolve/2 resolves field coordinates" do
      assert {:ok, field} = Coordinate.resolve(TestSchema, "User.email")
      assert field.identifier == :email
    end

    test "resolve/2 resolves argument coordinates" do
      assert {:ok, arg} = Coordinate.resolve(TestSchema, "Query.user(id:)")
      assert arg.identifier == :id
    end

    test "resolve/2 resolves directive coordinates" do
      assert {:ok, directive} = Coordinate.resolve(TestSchema, "@deprecated")
      assert directive.identifier == :deprecated
    end

    test "resolve/2 resolves directive argument coordinates" do
      assert {:ok, arg} = Coordinate.resolve(TestSchema, "@deprecated(reason:)")
      assert arg.identifier == :reason
    end

    test "resolve/2 returns error for non-existent type" do
      assert {:error, "Type not found: NonExistent"} = Coordinate.resolve(TestSchema, "NonExistent")
    end

    test "resolve/2 returns error for non-existent field" do
      assert {:error, "Field not found: User.nonexistent"} = Coordinate.resolve(TestSchema, "User.nonexistent")
    end

    test "resolve/2 returns error for non-existent argument" do
      assert {:error, "Argument not found: Query.user(nonexistent:)"} =
               Coordinate.resolve(TestSchema, "Query.user(nonexistent:)")
    end

    test "resolve/2 returns error for non-existent directive" do
      assert {:error, "Directive not found: @nonexistent"} = Coordinate.resolve(TestSchema, "@nonexistent")
    end

    test "resolve/2 returns error for invalid coordinate" do
      assert {:error, "Invalid schema coordinate: not valid!"} = Coordinate.resolve(TestSchema, "not valid!")
    end
  end

  describe "roundtrip" do
    test "generated coordinates can be parsed" do
      coordinates = [
        Coordinate.for_type("User"),
        Coordinate.for_field("User", "email"),
        Coordinate.for_argument("Query", "user", "id"),
        Coordinate.for_directive("deprecated"),
        Coordinate.for_directive_argument("deprecated", "reason")
      ]

      for coord <- coordinates do
        assert {:ok, _} = Coordinate.parse(coord)
      end
    end
  end
end
