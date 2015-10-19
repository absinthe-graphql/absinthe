defmodule Validation.DefaultSchema do

  alias ExGraphQL.Type

  def schema do
    %Type.Schema{query: query_root}
  end

  defp being do
    %Type.Interface{
      name: 'Being',
      fields: fn -> %{
                    name: %{
                      type: Type.String,
                      args: %{surname: %{type: Type.Boolean}}}}
      end}
  end

  defp pet do
    %Type.Interface{
      name: 'Pet',
      fields: fn -> %{
                    name: %{
                      type: Type.String,
                      args: %{surname: %{type: Type.Boolean}}}}
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
    %Type.Object{
      name: 'Dog',
      isTypeOf: fn ->
        true
      end,
      fields: fn -> %{
                    name: %{
                      type: Type.String,
                      args: %{surname: %{type: Type.Boolean}}},
                    nickname: %{type: Type.String},
                    barkVolume: %{type: Type.Int},
                    barks: %{type: Type.Boolean},
                    doesKnowCommand: %{
                      type: Type.Boolean,
                      args: %{dogCommand: %{type: dog_command}}},
                    isHousetrained: %{
                      type: Type.Boolean,
                      args: %{
                        atOtherHomes: %{
                          type: Type.Boolean,
                          defaultValue: true}}},
                    isAtLocation: %{
                      type: Type.Boolean,
                      args: %{x: %{type: Type.Int},
                              y: %{type: Type.Int}}}}
      end,
      interfaces: [being, pet]}
  end

  defp cat do
    %Type.Object{
      name: 'Cat',
      isTypeOf: fn ->
        true
      end,
      fields: fn -> %{
                    name: %{
                      type: Type.String,
                      args: %{surname: %{type: Type.Boolean}}},
                    nickname: %{type: Type.String},
                    meows: %{type: Type.Boolean},
                    meowVolume: %{type: Type.Int},
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
    %Type.Interface{
      name: 'Intelligent',
      fields: %{
        iq: %{type: Type.Int}
      }}
  end

  defp human do
    %Type.Object{
      name: 'Human',
      isTypeOf: fn -> true end,
    interfaces: [being, intelligent],
    fields: fn -> %{
                  name: %{
                    type: Type.String,
                    args: %{surname: %{type: Type.Boolean}}},
                  pets: %{type: %Type.List{type: pet}},
                  relatives: %{type: %Type.List{type: human}},
                  iq: %{type: Type.Int}}
    end}
  end

  defp alien do
    %Type.Object{
      name: 'Alien',
      isTypeOf: fn -> true end,
    interfaces: [being, intelligent],
    fields: %{
      iq: %{type: Type.Int},
      name: %{
        type: Type.String,
        args: %{surname: %{type: Type.Boolean}}},
      numEyes: %{type: Type.Int}}}
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
    %Type.InputObject{
      name: 'ComplexInput',
      fields: %{
        requiredField: %{type: %Type.NonNull{type: Type.Boolean}},
        intField: %{type: Type.Int},
        stringField: %{type: Type.String},
        booleanField: %{type: Type.Boolean},
        stringListField: %{type: %Type.List{type: Type.String}},
      }}
  end

  defp complicated_args do
    %Type.Object{
      name: 'ComplicatedArgs',
      # TODO List
      # TODO Coercion
      # TODO NotNulls
      fields: fn -> %{
                    intArgField: %{
                      type: Type.String,
                      args: %{intArg: %{type: Type.Int}}},
                    nonNullIntArgField: %{
                      type: Type.String,
                      args: %{nonNullIntArg: %{type: %Type.NonNull{type: Type.Int}}}},
                    stringArgField: %{
                      type: Type.String,
                      args: %{stringArg: %{type: Type.String}}},
                    booleanArgField: %{
                      type: Type.String,
                      args: %{booleanArg: %{type: Type.Boolean}}},
                    enumArgField: %{
                      type: Type.String,
                      args: %{enumArg: %{type: fur_color} }},
                    floatArgField: %{
                      type: Type.String,
                      args: %{floatArg: %{type: Type.Float}}},
                    idArgField: %{
                      type: Type.String,
                      args: %{idArg: %{type: Type.ID}}},
                    stringListArgField: %{
                      type: Type.String,
                      args: %{stringListArg: %{type: %Type.List{type: Type.String}}}},
                    complexArgField: %{
                      type: Type.String,
                      args: %{complexArg: %{type: complex_input}}},
                    multipleReqs: %{
                      type: Type.String,
                      args: %{
                        req1: %{type: %Type.NonNull{type: Type.Int}},
                        req2: %{type: %Type.NonNull{type: Type.Int}}}},
                    multipleOpts: %{
                      type: Type.String,
                      args: %{
                        opt1: %{
                          type: Type.Int,
                          defaultValue: 0},
                        opt2: %{
                          type: Type.Int,
                          defaultValue: 0}}},
                    multipleOptAndReq: %{
                      type: Type.String,
                      args: %{
                        req1: %{type: %Type.NonNull{type: Type.Int}},
                        req2: %{type: %Type.NonNull{type: Type.Int}},
                        opt1: %{
                          type: Type.Int,
                          defaultValue: 0},
                        opt2: %{
                          type: Type.Int,
                          defaultValue: 0}}}}
      end}
  end

  defp query_root do
    %Type.Object{
      name: 'QueryRoot',
      fields: fn -> %{
                    human: %{
                      args: %{id: %{type: Type.ID}},
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
