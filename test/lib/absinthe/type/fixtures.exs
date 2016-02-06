defmodule Absinthe.Type.Fixtures do
  use Absinthe.Schema

  query "Query", [
    fields: [
      article: [
        type: :article,
        args: [
          id: [type: :string]
        ]
      ],
      feed: [type: list_of(:article)]
    ]
  ]

  mutation "Mutation", [
    fields: [
      write_article: [type: :article]
    ]
  ]

  object :image, [
    fields: [
      url: [type: :string],
      width: [type: :integer],
      height: [type: :integer]
    ]
  ]

  object :type, [
    fields: [
      id: [type: :id],
      name: [type: :string],
      recent_article: [type: :article],
      pic: [
        type: :image,
        args: [
          width: [type: :integer],
          height: [type: :integer]
        ]
      ]
    ]
  ]

  object :article, [
    fields: [
      id: [type: :string],
      is_published: [type: :string],
      author: [type: :author],
      title: [type: :string],
      body: [type: :string]
    ]
  ]

end
