defmodule Absinthe.Type.Fixtures do

  use Absinthe.Schema
  alias Absinthe.Type

  @absinthe :type
  def image do
    %Type.Object{
      fields: fields(
        url: [type: :string],
        width: [type: :integer],
        height: [type: :integer]
      )
    }
  end

  @absinthe :type
  def author do
    %Type.Object{
      fields: fields(
        id: [type: :id],
        name: [type: :string],
        recent_article: [type: :article],
        pic: [
          type: :image,
          args: args(
            width: [type: :integer],
            height: [type: :integer]
          )
        ]
      )
    }
  end

  @absinthe :type
  def article do
    %Type.Object{
      fields: fields(
        id: [type: :string],
        is_published: [type: :string],
        author: [type: :author],
        title: [type: :string],
        body: [type: :string]
      )
    }
  end

  def query do
    %Type.Object{
      name: "Query",
      fields: fields(
        article: [
          type: :article,
          args: args(
            id: [type: :string]
          )
        ],
        feed: [type: list_of(:article)]
      )
    }
  end

  def mutation do
    %Type.Object{
      name: "Mutation",
      fields: fields(
        write_article: [type: :article]
      )
    }
  end

  @absinthe :type
  def object_type do
    %Type.Object{
      is_type_of: fn -> true end
    }
  end

end
