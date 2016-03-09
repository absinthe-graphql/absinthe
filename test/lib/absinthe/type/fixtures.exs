defmodule Absinthe.Type.Fixtures do
  use Absinthe.Schema

  query name: "Query" do
    field :article,
      type: :article,
      args: [
        id: [type: :string]
      ]
    field :feed, list_of(:article)
  end

  mutation name: "Mutation" do
    field :write_article, :article
  end

  object :image do
    field :url, :string
    field :width, :integer
    field :height, :integer
  end

  object :type do
    field :id, :id
    field :name, :string
    field :recent_article, :article
    field :pic,
      type: :image,
      args: [
        width: [type: :integer],
        height: [type: :integer]
      ]
  end

  object :article do
    field :id, :string
    field :is_published, :string
    field :title, :string
    field :body, :string
  end

end
