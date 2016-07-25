defmodule Absinthe.Language.IDLtest do
  use Absinthe.Case, async: true

  defmodule StubSchema do
    use Absinthe.Schema
    query do
      # ...
    end
  end

  describe "object and interface types" do

    @idl """
    interface Authored {
      author: User
    }
    type Article implements Authored {
      author: User
    }
    type User {
      articles: [Article]
    }
    """

    defmodule ObjectSchema do
      use Absinthe.Schema

      interface :authored do
        field :author, :user
        resolve_type fn
          _, _ ->
            :article
        end
      end

      object :article do
        field :author, :user
        interface :authored
      end

      object :user do
        field :articles, list_of(:article)
      end

    end

    it "are parsed from IDL" do
      assert {:ok, _} = Absinthe.parse(@idl)
    end

    it "can be converted to IDL AST" do
      assert %Absinthe.Language.ObjectDefinition{} = Absinthe.Language.IDL.to_idl_ast(ObjectSchema.__absinthe_type__(:article), ObjectSchema)
    end

    it "can be converted to IDL iodata" do
      equiv_idl = """
      type Article implements Authored {
        author: User
      }
      """
      {:ok, equiv_idl_ast_doc} = Absinthe.parse(equiv_idl)
      equiv_idl_ast = equiv_idl_ast_doc.definitions |> List.first
      equiv_idl_iodata = Absinthe.Language.IDL.to_idl_iodata(equiv_idl_ast, ObjectSchema)

      idl_ast = ObjectSchema.__absinthe_type__(:article) |> Absinthe.Language.IDL.to_idl_ast(ObjectSchema)
      idl_iodata = Absinthe.Language.IDL.to_idl_iodata(idl_ast, ObjectSchema)
      assert idl_iodata == equiv_idl_iodata
    end
    it "can be converted to IDL iodata as a schema" do
      assert Absinthe.Language.IDL.to_idl_iodata(ObjectSchema |> Absinthe.Language.IDL.to_idl_ast, ObjectSchema)
    end

  end

  describe "directives" do

    @idl """
    directive @foo(arg: Int) on FIELD
    """

    defmodule DirectiveSchema do
      use Absinthe.Schema

      query do
        # ...
      end

      directive :foo do
        arg :arg, :integer
        on :field
      end

    end

    it "can be parsed from the IDL" do
      assert {:ok, _} = Absinthe.parse(@idl)
    end

  end

  describe "input object types" do

    @idl """
    input InputArticle {
      author: User
    }
    input InputUser {
      articles: [Article]
    }
    """

    defmodule InputObjectSchema do
      use Absinthe.Schema

      input_object :input_article do
        field :author, :input_user
        field :publish, :boolean, default_value: true
        field :tags, list_of(:string), default_value: ~w(a b c)
      end

      input_object :input_user do
        field :articles, list_of(:input_article)
      end

    end

    it "are parsed from IDL" do
      assert {:ok, _} = Absinthe.parse(@idl)
    end

    it "can be converted to IDL AST" do
      assert %Absinthe.Language.InputObjectDefinition{} = Absinthe.Language.IDL.to_idl_ast(InputObjectSchema.__absinthe_type__(:input_article), InputObjectSchema)
    end

    # Note: This only tests that input object defaults parsed in from IDL
    # are successfully emitted back, not that they can be set in Absinthe schema notation
    it "can be provided as defaults" do
      idl = """
      type QueryRoot {
        createThing(input: InputThing = {name: "Boo"}): Thing
      }
      """
      {:ok, idl_ast_doc} = Absinthe.parse(idl)
      idl_ast = idl_ast_doc.definitions |> List.first
      idl_iodata = Absinthe.Language.IDL.to_idl_iodata(idl_ast, StubSchema)
      assert idl == IO.iodata_to_binary(idl_iodata)
    end

    it "can be converted to IDL iodata" do
      equiv_idl = """
      input InputArticle {
        author: InputUser
        publish: Boolean = true
        tags: [String] = ["a", "b", "c"]
      }
      """
      {:ok, equiv_idl_ast_doc} = Absinthe.parse(equiv_idl)
      equiv_idl_ast = equiv_idl_ast_doc.definitions |> List.first
      equiv_idl_iodata = Absinthe.Language.IDL.to_idl_iodata(equiv_idl_ast, InputObjectSchema)

      idl_ast = InputObjectSchema.__absinthe_type__(:input_article) |> Absinthe.Language.IDL.to_idl_ast(InputObjectSchema)

      idl_iodata = Absinthe.Language.IDL.to_idl_iodata(idl_ast, InputObjectSchema)
      assert idl_iodata == equiv_idl_iodata
    end
    it "can be converted to IDL iodata as a schema" do
      assert Absinthe.Language.IDL.to_idl_iodata(InputObjectSchema |> Absinthe.Language.IDL.to_idl_ast, ObjectSchema)
    end

  end

  describe "multiple args" do

    it "are output" do

      idl = """
      type User implements Node {
        id: ID!
        todos(status: String = "any", after: String, first: Int, before: String, last: Int): TodoConnection
        numTodos: Int
        numCompletedTodos: Int
      }
      """
      {:ok, idl_ast_doc} = Absinthe.parse(idl)
      idl_ast = idl_ast_doc.definitions |> List.first
      idl_iodata = idl_ast |> Absinthe.Language.IDL.to_idl_iodata(StubSchema)
      assert idl == IO.iodata_to_binary(idl_iodata)
    end

  end

  describe "enums" do

    @idl """
    enum Color {
      BLUE
      GREEN
      RED
    }
    type Sprite {
      fill(color: Color = BLUE): Image
    }
    type Image {
      data: String
    }
    """

    defmodule EnumSchema do
      use Absinthe.Schema

      enum :color do
        value :red
        value :green
        value :blue
      end

      object :sprite do
        field :fill, :image do
          arg :color, :color, default_value: "BLUE"
        end
      end

      object :image do
        field :data, :string
      end

    end

    it "are parsed from IDL" do
      assert {:ok, _} = Absinthe.parse(@idl)
    end

    it "can be converted to IDL AST" do
      assert %Absinthe.Language.EnumTypeDefinition{} = Absinthe.Language.IDL.to_idl_ast(EnumSchema.__absinthe_type__(:color), EnumSchema)
    end

    it "can be converted to IDL iodata" do
      equiv_idl = """
      enum Color {
        BLUE
        GREEN
        RED
      }
      """
      {:ok, equiv_idl_ast_doc} = Absinthe.parse(equiv_idl)
      equiv_idl_ast = equiv_idl_ast_doc.definitions |> List.first
      equiv_idl_iodata = Absinthe.Language.IDL.to_idl_iodata(equiv_idl_ast, EnumSchema)

      idl_ast = EnumSchema.__absinthe_type__(:color) |> Absinthe.Language.IDL.to_idl_ast(EnumSchema)
      idl_iodata = Absinthe.Language.IDL.to_idl_iodata(idl_ast, EnumSchema)
      assert idl_iodata == equiv_idl_iodata
    end
    it "can be converted to IDL iodata as a schema" do
      assert Absinthe.Language.IDL.to_idl_iodata(EnumSchema |> Absinthe.Language.IDL.to_idl_ast, EnumSchema)
    end

  end

  describe "unions" do

    @idl """
    type Person {
      name: String
      age: Int
    }
    type Business {
      name: String
      employeeCount: Int
    }
    union SearchResult = Business | Person
    """

    defmodule UnionSchema do
      use Absinthe.Schema

      object :person do
        field :name, :string
        field :age, :integer
      end

      object :business do
        field :name, :string
        field :employee_count, :integer
      end

      union :search_result do
        types [:person, :business]
        resolve_type fn
          %{age: _}, _ ->
            :person
          _, _ ->
            :business
        end

      end

    end

    it "are parsed from IDL" do
      assert {:ok, _} = Absinthe.parse(@idl)
    end

    it "can be converted to IDL AST" do
      assert %Absinthe.Language.UnionTypeDefinition{} = Absinthe.Language.IDL.to_idl_ast(UnionSchema.__absinthe_type__(:search_result), UnionSchema)
    end

    it "can be converted to IDL iodata" do
      equiv_idl = """
      union SearchResult = Person | Business

      """
      {:ok, equiv_idl_ast_doc} = Absinthe.parse(equiv_idl)
      equiv_idl_ast = equiv_idl_ast_doc.definitions |> List.first
      equiv_idl_iodata = Absinthe.Language.IDL.to_idl_iodata(equiv_idl_ast, EnumSchema)

      idl_ast = UnionSchema.__absinthe_type__(:search_result) |> Absinthe.Language.IDL.to_idl_ast(UnionSchema)
      idl_iodata = Absinthe.Language.IDL.to_idl_iodata(idl_ast, UnionSchema)
      assert idl_iodata == equiv_idl_iodata
    end
    it "can be converted to IDL iodata as a schema" do
      assert Absinthe.Language.IDL.to_idl_iodata(UnionSchema |> Absinthe.Language.IDL.to_idl_ast, UnionSchema)
    end

  end

  describe "scalars" do

    @idl """
    scalar Time

    """

    defmodule ScalarSchema do
      use Absinthe.Schema

      scalar :time do
        parse fn _ -> {:ok, :stub} end
        serialize fn _ -> "stub" end
      end

    end

    it "are parsed from IDL" do
      assert {:ok, _} = Absinthe.parse(@idl)
    end

    it "can be converted to IDL AST" do
      assert %Absinthe.Language.ScalarTypeDefinition{} = Absinthe.Language.IDL.to_idl_ast(ScalarSchema.__absinthe_type__(:time), ScalarSchema)
    end

    it "can be converted to IDL iodata" do
      {:ok, equiv_idl_ast_doc} = Absinthe.parse(@idl)
      equiv_idl_ast = equiv_idl_ast_doc.definitions |> List.first
      equiv_idl_iodata = Absinthe.Language.IDL.to_idl_iodata(equiv_idl_ast, ScalarSchema)

      idl_ast = ScalarSchema.__absinthe_type__(:time) |> Absinthe.Language.IDL.to_idl_ast(ScalarSchema)
      idl_iodata = Absinthe.Language.IDL.to_idl_iodata(idl_ast, ScalarSchema)
      assert idl_iodata == equiv_idl_iodata
    end
    it "can be converted to IDL iodata as a schema" do
      assert Absinthe.Language.IDL.to_idl_iodata(ScalarSchema |> Absinthe.Language.IDL.to_idl_ast, ScalarSchema)
    end

  end

end
