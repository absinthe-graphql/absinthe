defmodule Absinthe.Language.IDLtest do
  use ExSpec, async: true

  describe "object types" do

    @idl """
    type Article {
      author: User
    }
    type User {
      articles: [Article]
    }
    """

    defmodule ObjectSchema do
      use Absinthe.Schema

      object :article do
        field :author, :user
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
      type Article {
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

end
