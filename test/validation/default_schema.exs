defmodule Validation.DefaultSchema do

  alias ExGraphQL.Type

  def schema do
    %Type.Schema{query: query_root}
  end

  defp being do
    %Type.InterfaceType{
      name: 'Being',
      fields: fn -> %{
                    name: %{
                      type: Type.Scalar.string,
                      args: %{surname: %{type: Type.Scalar.boolean}}}}
      end}
  end

  defp pet do
    %Type.InterfaceType{
      name: 'Pet',
      fields: fn -> %{
                    name: %{
                      type: Type.Scalar.string,
                      args: %{surname: %{type: Type.Scalar.boolean}}}}
      end}
  end

  defp dog_command do
    %Type.Enum{
      name: 'DogCommand',
      values: %{
        SIT: %{value: 0},
        HEEL: %{value: 1},
        DOWN: %{value: 2}}}
  end

  defp dog do
    %Type.ObjectType{
      name: 'Dog',
      is_type_of: fn ->
        true
      end,
      fields: fn -> %{
                    name: %{
                      type: Type.Scalar.string,
                      args: %{surname: %{type: Type.Scalar.boolean}}},
                    nickname: %{type: Type.Scalar.string},
                    barkVolume: %{type: Type.Scalar.integer},
                    barks: %{type: Type.Scalar.boolean},
                    doesKnowCommand: %{
                      type: Type.Scalar.boolean,
                      args: %{dogCommand: %{type: dog_command}}},
                    isHousetrained: %{
                      type: Type.Scalar.boolean,
                      args: %{
                        atOtherHomes: %{
                          type: Type.Scalar.boolean,
                          defaultValue: true}}},
                    isAtLocation: %{
                      type: Type.Scalar.boolean,
                      args: %{x: %{type: Type.Scalar.integer},
                              y: %{type: Type.Scalar.integer}}}}
      end,
      interfaces: [being, pet]}
  end

  defp cat do
    %Type.ObjectType{
      name: 'Cat',
      is_type_of: fn ->
        true
      end,
      fields: fn -> %{
                    name: %{
                      type: Type.Scalar.string,
                      args: %{surname: %{type: Type.Scalar.boolean}}},
                    nickname: %{type: Type.Scalar.string},
                    meows: %{type: Type.Scalar.boolean},
                    meowVolume: %{type: Type.Scalar.integer},
                    furColor: %{type: FurColor}}
      end,
      interfaces: [being, pet]}
  end

  defp cat_or_dog do
    %Type.Union{
      name: 'CatOrDog',
      types: [dog, cat],
      resolveType: fn ->
        # not used for validation
      end}
  end

  defp intelligent do
    %Type.InterfaceType{
      name: 'Intelligent',
      fields: %{
        iq: %{type: Type.Scalar.integer}
      }}
  end

  defp human do
    %Type.ObjectType{
      name: 'Human',
      is_type_of: fn -> true end,
    interfaces: [being, intelligent],
    fields: fn -> %{
                  name: %{
                    type: Type.Scalar.string,
                    args: %{surname: %{type: Type.Scalar.boolean}}},
                  pets: %{type: %Type.List{of_type: pet}},
                  relatives: %{type: %Type.List{of_type: human}},
                  iq: %{type: Type.Scalar.integer}}
    end}
  end

  defp alien do
    %Type.ObjectType{
      name: 'Alien',
      is_type_of: fn -> true end,
    interfaces: [being, intelligent],
    fields: %{
      iq: %{type: Type.Scalar.integer},
      name: %{
        type: Type.Scalar.string,
        args: %{surname: %{type: Type.Scalar.boolean}}},
      numEyes: %{type: Type.Scalar.integer}}}
  end

  defp dog_or_human do
    %Type.Union{
      name: 'DogOrHuman',
      types: [dog, human],
      resolveType: fn ->
        # not used for validation
      end}
  end

  defp human_or_alien do
    %Type.Union{
      name: 'HumanOrAlien',
      types: [human, alien],
      resolveType: fn ->
        # not used for validation
      end}
  end

  defp fur_color do
    %Type.Enum{
      name: 'FurColor',
      values: %{
        BROWN: %{value: 0},
        BLACK: %{value: 1},
        TAN: %{value: 2},
        SPOTTED: %{value: 3},
      }}
  end

  defp complex_input do
    %Type.InputObjectType{
      name: 'ComplexInput',
      fields: %{
        requiredField: %{type: %Type.NonNull{of_type: Type.Scalar.boolean}},
        intField: %{type: Type.Scalar.integer},
        stringField: %{type: Type.Scalar.string},
        booleanField: %{type: Type.Scalar.boolean},
        stringListField: %{type: %Type.List{of_type: Type.Scalar.string}},
      }}
  end

  defp complicated_args do
    %Type.ObjectType{
      name: 'ComplicatedArgs',
      # TODO List
      # TODO Coercion
      # TODO NotNulls
      fields: fn -> %{
                    intArgField: %{
                      type: Type.Scalar.string,
                      args: %{intArg: %{type: Type.Scalar.integer}}},
                    nonNullIntArgField: %{
                      type: Type.Scalar.string,
                      args: %{nonNullIntArg: %{type: %Type.NonNull{of_type: Type.Scalar.integer}}}},
                    stringArgField: %{
                      type: Type.Scalar.string,
                      args: %{stringArg: %{type: Type.Scalar.string}}},
                    booleanArgField: %{
                      type: Type.Scalar.string,
                      args: %{booleanArg: %{type: Type.Scalar.boolean}}},
                    enumArgField: %{
                      type: Type.Scalar.string,
                      args: %{enumArg: %{type: fur_color} }},
                    floatArgField: %{
                      type: Type.Scalar.string,
                      args: %{floatArg: %{type: Type.Float}}},
                    idArgField: %{
                      type: Type.Scalar.string,
                      args: %{idArg: %{type: Type.Scalar.id}}},
                    stringListArgField: %{
                      type: Type.Scalar.string,
                      args: %{stringListArg: %{type: %Type.List{of_type: Type.Scalar.string}}}},
                    complexArgField: %{
                      type: Type.Scalar.string,
                      args: %{complexArg: %{type: complex_input}}},
                    multipleReqs: %{
                      type: Type.Scalar.string,
                      args: %{
                        req1: %{type: %Type.NonNull{of_type: Type.Scalar.integer}},
                        req2: %{type: %Type.NonNull{of_type: Type.Scalar.integer}}}},
                    multipleOpts: %{
                      type: Type.Scalar.string,
                      args: %{
                        opt1: %{
                          type: Type.Scalar.integer,
                          defaultValue: 0},
                        opt2: %{
                          type: Type.Scalar.integer,
                          defaultValue: 0}}},
                    multipleOptAndReq: %{
                      type: Type.Scalar.string,
                      args: %{
                        req1: %{type: %Type.NonNull{of_type: Type.Scalar.integer}},
                        req2: %{type: %Type.NonNull{of_type: Type.Scalar.integer}},
                        opt1: %{
                          type: Type.Scalar.integer,
                          defaultValue: 0},
                        opt2: %{
                          type: Type.Scalar.integer,
                          defaultValue: 0}}}}
      end}
  end

  defp query_root do
    %Type.ObjectType{
      name: 'QueryRoot',
      fields: fn -> %{
                    human: %{
                      args: %{id: %{type: Type.Scalar.id}},
                      type: human},
                    alien: %{type: alien},
                    dog: %{type: dog},
                    cat: %{type: cat},
                    pet: %{type: pet},
                    catOrDog: %{type: cat_or_dog},
                    dogOrHuman: %{type: dog_or_human},
                    humanOrAlien: %{type: human_or_alien},
                    complicatedArgs: %{type: complicated_args}}
      end}
  end

end
