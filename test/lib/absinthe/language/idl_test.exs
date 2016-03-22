defmodule Absinthe.Language.IDLtest do
  use ExSpec, async: true

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
            {:ok, :article}
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
      equiv_idl_iodata = Absinthe.Language.IDL.to_idl_iodata(equiv_idl_ast)

      idl_ast = ObjectSchema.__absinthe_type__(:article) |> Absinthe.Language.IDL.to_idl_ast(ObjectSchema)
      idl_iodata = Absinthe.Language.IDL.to_idl_iodata(idl_ast)
      assert idl_iodata == equiv_idl_iodata
    end
    it "can be converted to IDL iodata as a schema" do
      assert Absinthe.Language.IDL.to_idl_iodata(ObjectSchema |> Absinthe.Language.IDL.to_idl_ast)
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
      equiv_idl_iodata = Absinthe.Language.IDL.to_idl_iodata(equiv_idl_ast)

      idl_ast = InputObjectSchema.__absinthe_type__(:input_article) |> Absinthe.Language.IDL.to_idl_ast(InputObjectSchema)

      idl_iodata = Absinthe.Language.IDL.to_idl_iodata(idl_ast)
      assert idl_iodata == equiv_idl_iodata
    end
    it "can be converted to IDL iodata as a schema" do
      assert Absinthe.Language.IDL.to_idl_iodata(InputObjectSchema |> Absinthe.Language.IDL.to_idl_ast)
    end

  end



end
