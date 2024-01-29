defmodule Absinthe.Fixtures.ContactSchema do
  use Absinthe.Schema
  use Absinthe.Fixture

  @bruce %{name: "Bruce", age: 35}
  @others [
    %{name: "Joe", age: 21},
    %{name: "Jill", age: 43}
  ]
  @business %{name: "Someplace", employee_count: 11}

  query do
    field :person,
      type: :person,
      resolve: fn _, _ ->
        {:ok, @bruce}
      end

    field :contact,
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

    field :first_search_result,
      type: :search_result,
      resolve: fn _, _ ->
        {:ok, @bruce}
      end

    field :search_results,
      type: non_null(list_of(non_null(:search_result))),
      resolve: fn _, _ ->
        {:ok, [@bruce, @business]}
      end

    field :profile,
      type: :person,
      args: [name: [type: non_null(:string)]],
      resolve: fn
        %{name: "Bruce"}, _ ->
          {:ok, @bruce}

        _, _ ->
          {:ok, nil}
      end
  end

  mutation do
    field :person,
      type: :person,
      args: [
        profile: [type: :profile_input]
      ],
      resolve: fn %{profile: profile} ->
        # Return it like it's a person
        {:ok, profile}
      end
  end

  subscription do
    field :contact_added, :person
  end

  input_object :profile_input do
    description "The basic details for a person"

    field :code, type: non_null(:string)
    field :name, type: :string, description: "The person's name", default_value: "Janet"
    field :age, type: :integer, description: "The person's age", default_value: 43
    field :address, type: :string, deprecate: "change of privacy policy"
  end

  interface :named_entity do
    description "A named entity"

    field :name, type: :string

    resolve_type fn
      %{age: _}, _ ->
        :person

      %{employee_count: _}, _ ->
        :business
    end
  end

  object :person do
    description "A person"

    field :name, :string
    field :age, :integer
    field :address, :string, deprecate: "change of privacy policy"

    field :others,
      type: list_of(:person),
      resolve: fn _, _ ->
        {:ok, @others}
      end

    interface :named_entity
  end

  object :business do
    description "A business"

    field :name, :string
    field :employee_count, :integer
    interface :named_entity
  end

  union :search_result do
    description "A search result"

    types [:business, :person]

    resolve_type fn
      %{age: _}, _ ->
        :person

      %{employee_count: _}, _ ->
        :business
    end
  end

  object :contact do
    field :entity, :named_entity
    import_fields :contact_method
  end

  object :contact_method do
    field :phone_number, :string
    field :address, :string
  end

  scalar :name do
    serialize &to_string/1

    parse fn
      %Absinthe.Blueprint.Input.String{} = string ->
        string.value

      _ ->
        :error
    end
  end

  object :unused do
    field :an_unused_field, :string
  end
end
