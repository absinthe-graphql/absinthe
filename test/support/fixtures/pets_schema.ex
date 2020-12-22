defmodule Absinthe.Fixtures.PetsSchema do
  use Absinthe.Schema
  use Absinthe.Fixture

  interface :being do
    field :name, :string do
      arg :surname, :boolean
    end
  end

  interface :pet do
    field :name, :string do
      arg :surname, :boolean
    end
  end

  interface :canine do
    field :name, :string do
      arg :surname, :boolean
    end
  end

  enum :dog_command do
    value :sit, as: 0
    value :heel, as: 1
    value :down, as: 2
  end

  object :dog do
    is_type_of fn _ -> true end

    field :name, :string do
      arg :surname, :boolean
    end

    field :nickname, :string
    field :bark_volume, :integer
    field :barks, :boolean

    field :does_know_command, :boolean do
      arg :dog_command, :dog_command
    end

    field :is_housetrained, :boolean do
      arg :at_other_homes, :boolean, default_value: true
    end

    field :is_at_location, :boolean do
      arg :x, :integer
      arg :y, :integer
    end

    interfaces [:being, :pet, :canine]
  end

  object :cat do
    is_type_of fn _ -> true end

    field :name, :string do
      arg :surname, :boolean
    end

    field :nickname, :string
    field :meows, :boolean
    field :meow_volume, :integer
    field :fur_color, :fur_color
    interfaces [:being, :pet]
  end

  union :cat_or_dog do
    types [:dog, :cat]
  end

  interface :intelligent do
    field :iq, :integer
  end

  object :human do
    is_type_of fn _ -> true end
    interfaces [:being, :intelligent]

    field :name, :string do
      arg :surname, :boolean
    end

    field :pets, list_of(:pet)
    field :relatives, list_of(:human)
    field :iq, :integer
  end

  object :alien do
    is_type_of fn _ -> true end
    interfaces [:being, :intelligent]
    field :iq, :integer

    field :name, :string do
      arg :surname, :boolean
    end

    field :num_eyes, :integer
  end

  union :dog_or_human do
    types [:dog, :human]
  end

  union :human_or_alien do
    types [:human, :alien]
  end

  enum :fur_color do
    value :brown, as: 0
    value :black, as: 1
    value :tan, as: 2
    value :spotted, as: 3
  end

  input_object :complex_input do
    field :required_field, non_null(:boolean)
    field :int_field, :integer
    field :string_field, :string
    field :boolean_field, :boolean
    field :string_list_field, list_of(:string)
  end

  scalar :custom_scalar do
    parse & &1
    serialize & &1
  end

  object :complicated_args do
    field :int_arg_field, :string do
      arg :int_arg, :integer
    end

    field :non_null_int_arg_field, :string do
      arg :non_null_int_arg, non_null(:integer)
    end

    field :string_arg_field, :string do
      arg :string_arg, :string
    end

    field :boolean_arg_field, :string do
      arg :boolean_arg, :boolean
    end

    field :float_arg_field, :string do
      arg :float_arg, :float
    end

    field :id_arg_field, :string do
      arg :id_arg, :id
    end

    field :string_list_arg_field, :string do
      arg :string_list_arg, list_of(:string)
    end

    field :string_list_of_list_arg_field, :string do
      arg :string_list_of_list_arg, list_of(list_of(:string))
    end

    field :complex_arg_field, :string do
      arg :complex_arg, :complex_input
      arg :complex_arg_list, list_of(:complex_input)
    end

    field :multiple_reqs, :string do
      arg :req1, non_null(:integer)
      arg :req2, non_null(:integer)
    end

    field :multiple_opts, :string do
      arg :opt1, :integer, default_value: 0
      arg :opt2, :integer, default_value: 0
    end

    field :multiple_opt_and_req, :string do
      arg :req1, non_null(:integer)
      arg :req2, non_null(:integer)
      arg :opt1, :integer, default_value: 0
      arg :opt2, :integer, default_value: 0
    end
  end

  query do
    field :human, :human do
      arg :id, :id
    end

    field :alien, :alien
    field :dog, :dog
    field :cat, :cat
    field :pet, :pet
    field :cat_or_dog, :cat_or_dog
    field :dog_or_human, :dog_or_human
    field :human_or_alien, :human_or_alien
    field :complicated_args, :complicated_args
  end

  mutation do
    field :create_dog, :dog do
      arg :custom_scalar_input, non_null(:custom_scalar)
    end
  end

  directive :on_query do
    on [:query]
  end

  directive :on_mutation do
    on [:mutation]
  end

  directive :on_subscription do
    on [:subscription]
  end

  directive :on_field do
    repeatable true
    on [:field]
  end

  directive :on_fragment_definition do
    on [:fragment_definition]
  end

  directive :on_fragment_spread do
    on [:fragment_spread]
  end

  directive :on_inline_fragment do
    on [:inline_fragment]
  end

  directive :on_schema do
    on [:schema]
  end

  directive :on_scalar do
    on [:scalar]
  end

  directive :on_object do
    on [:object]
  end

  directive :on_field_definition do
    on [:field_definition]
  end

  directive :on_argument_definition do
    on [:argument_definition]
  end

  directive :on_interface do
    on [:interface]
  end

  directive :on_union do
    on [:union]
  end

  directive :on_enum do
    on [:enum]
  end

  directive :on_enum_value do
    on [:enum_value]
  end

  directive :on_input_object do
    on [:input_object]
  end

  directive :on_input_field_definition do
    on [:input_field_definition]
  end
end
