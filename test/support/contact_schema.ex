defmodule ContactSchema do
  use Absinthe.Schema

  @bruce %{name: "Bruce", age: 35}
  @others [
    %{name: "Joe", age: 21},
    %{name: "Jill", age: 43}
  ]
  @business %{name: "Someplace", employee_count: 11}

  query [
    fields: [
      person: [
        type: :person,
        resolve: fn
          _, _ ->
            {:ok, @bruce}
        end
      ],
      contact: [
        type: :contact,
        args: [
          business: [type: :boolean, default_value: false]
        ],
        resolve: fn
          %{business: false}, _ ->
            {:ok, %{entity: @bruce}}
          %{business: true}, _ ->
            {:ok, %{entity: @business}}
        end
      ],
      first_search_result: [
        type: :search_result,
        resolve: fn
          _, _ ->
            {:ok, @bruce}
        end
      ],
      profile: [
        type: :person,
        args: [
          name: [type: non_null(:string)]
        ],
        resolve: fn
          %{name: "Bruce"}, _ ->
            {:ok, @bruce}
          _, _ ->
            {:ok, nil}
        end
      ]
    ]
  ]

  mutation [
    fields: [
      person: [
        type: :person,
        args: [
          profile: [type: :profile_input]
        ],
        resolve: fn
          %{profile: profile} ->
            # Return it like it's a person
            {:ok, profile}
        end
      ]
    ]
  ]

  @doc "The basic details for a person"
  input_object :profile_input, [
    fields: [
      code: [type: non_null(:string)],
      name: [type: :string, description: "The person's name", default_value: "Janet"],
      age: [type: :integer, description: "The person's age", default_value: 43]
    ]
  ]

  @doc "A named entity"
  interface :named_entity, [
    fields: [
      name: [type: :string]
    ],
    resolve_type: fn
      %{age: _}, _ ->
        :person
      %{employee_count: _}, _ ->
        :business
    end
  ]

  @doc "A person"
  object :person, [
    fields: [
      name: [type: :string],
      age: [type: :integer],
      address: deprecate([type: :string], reason: "change of privacy policy"),
      others: [
        type: list_of(:person),
        resolve: fn
          _, _ ->
            {:ok, @others}
        end
      ]
    ],
    interfaces: [:named_entity]
  ]

  @doc "A business"
  object :business, [
    fields: [
      name: [type: :string],
      employee_count: [type: :integer]
    ],
    interfaces: [:named_entity]
  ]

  @doc "A search result"
  union :search_result, [
    types: [:business, :person],
    resolve_type: fn
      %{age: _}, _ ->
        :person
      %{employee_count: _}, _ ->
        :business
    end
  ]

  object :contact, [
    fields: [
      entity: [type: :named_entity],
      phone_number: [type: :string],
      address: [type: :string]
    ]
  ]

end
