defmodule Type.DefinitionTest do
  use ExSpec, async: true

  alias Type.Fixtures
  alias ExGraphQL.Type.FieldDefinitionMap
  alias ExGraphQL.Type

  it "defines a query only schema" do

    blog_schema = %ExGraphQL.Type.Schema{query: Fixtures.blog_query}
    assert blog_schema.query == Fixtures.blog_query

    article_field = FieldDefinitionMap.get(Fixtures.blog_query.fields, :article)
    assert article_field.type == Fixtures.blog_article
    assert article_field.type.name == "Article"
    assert article_field.name == "article"

    title_field = FieldDefinitionMap.get(article_field.type.fields, :title)
    assert title_field.name == "title"
    assert title_field.type == ExGraphQL.Type.Scalar.string
    assert title_field.type.name == "String"

    author_field = FieldDefinitionMap.get(article_field.type.fields, :author)
    recent_article_field = FieldDefinitionMap.get(author_field.type.fields, :recent_article)
    assert recent_article_field.type == Fixtures.blog_article

    feed_field = FieldDefinitionMap.get(Fixtures.blog_query.fields, :feed)
    assert feed_field.type.of_type == Fixtures.blog_article
    assert feed_field.name == "feed"
  end

  it "defines a mutation schema" do
    blog_schema = %ExGraphQL.Type.Schema{query: Fixtures.blog_query,
                                         mutation: Fixtures.blog_mutation}
    assert blog_schema.mutation == Fixtures.blog_mutation

    write_mutation = FieldDefinitionMap.get(Fixtures.blog_mutation.fields, :write_article)
    assert write_mutation.type == Fixtures.blog_article
    assert write_mutation.type.name == "Article"
    assert write_mutation.name == "write_article"
  end

  it "includes nested input objects in the map" do
    nested_input_object = %Type.InputObjectType{
      name: "NestedInputObject",
      fields: %{value: %{type: Type.Scalar.string}}}
    some_input_object = %Type.InputObjectType{
      name: "SomeInputObject",
      fields: %{nested: %{type: nested_input_object}}}
    some_mutation = %Type.ObjectType{
      name: "SomeMutation",
      fields: %{
        mutateSomething: %{
          type: Fixtures.blog_article,
          args: %{input: %{type: some_input_object}}}}}
    {:ok, schema} = Type.Schema.create(query: Fixtures.blog_query,
                                       mutation: some_mutation)
    assert schema.type_map |> Map.get("NestedInputObject") == nested_input_object
  end

  # it("includes nested input objects in the map", fn -> {
  #   var NestedInputObject = new GraphQLInputObjectType({
  #     name: "NestedInputObject",
  #     fields: { value: { type: GraphQLString } }
  #   });
  #   var SomeInputObject = new GraphQLInputObjectType({
  #     name: "SomeInputObject",
  #     fields: { nested: { type: NestedInputObject } }
  #   });
  #   var SomeMutation = new GraphQLObjectType({
  #     name: "SomeMutation",
  #     fields: {
  #       mutateSomething: {
  #         type: BlogArticle,
  #         args: { input: { type: SomeInputObject } }
  #       }
  #     }
  #   });
  #   var schema = new GraphQLSchema({
  #     query: BlogQuery,
  #     mutation: SomeMutation,
  #   });
  #   expect(schema.getTypeMap().NestedInputObject).to.equal(NestedInputObject);
  # });

  # it("includes interfaces\" subtypes in the type map", fn -> {
  #   var SomeInterface = new GraphQLInterfaceType({
  #     name: "SomeInterface",
  #     fields: {
  #       f: { type: GraphQLInt }
  #     }
  #   });

  #   var SomeSubtype = new GraphQLObjectType({
  #     name: "SomeSubtype",
  #     fields: {
  #       f: { type: GraphQLInt }
  #     },
  #     interfaces: [ SomeInterface ],
  #     isTypeOf: fn -> true
  #   });

  #   var schema = new GraphQLSchema({
  #     query: new GraphQLObjectType({
  #       name: "Query",
  #       fields: {
  #         iface: { type: SomeInterface }
  #       }
  #     })
  #   });

  #   expect(schema.getTypeMap().SomeSubtype).to.equal(SomeSubtype);
  # });

  # it("includes interfaces\" thunk subtypes in the type map", fn -> {
  #   var SomeInterface = new GraphQLInterfaceType({
  #     name: "SomeInterface",
  #     fields: {
  #       f: { type: GraphQLInt }
  #     }
  #   });

  #   var SomeSubtype = new GraphQLObjectType({
  #     name: "SomeSubtype",
  #     fields: {
  #       f: { type: GraphQLInt }
  #     },
  #     interfaces: fn -> [ SomeInterface ],
  #     isTypeOf: fn -> true
  #   });

  #   var schema = new GraphQLSchema({
  #     query: new GraphQLObjectType({
  #       name: "Query",
  #       fields: {
  #         iface: { type: SomeInterface }
  #       }
  #     })
  #   });

  #   expect(schema.getTypeMap().SomeSubtype).to.equal(SomeSubtype);
  # });


  # it("stringifies simple types", fn -> {

  #   expect(String(GraphQLInt)).to.equal("Int");
  #   expect(String(BlogArticle)).to.equal("Article");
  #   expect(String(InterfaceType)).to.equal("Interface");
  #   expect(String(UnionType)).to.equal("Union");
  #   expect(String(EnumType)).to.equal("Enum");
  #   expect(String(InputObjectType)).to.equal("InputObject");
  #   expect(
  #     String(new GraphQLNonNull(GraphQLInt))
  #   ).to.equal("Int!");
  #   expect(
  #     String(new GraphQLList(GraphQLInt))
  #   ).to.equal("[Int]");
  #   expect(
  #     String(new GraphQLNonNull(new GraphQLList(GraphQLInt)))
  #   ).to.equal("[Int]!");
  #   expect(
  #     String(new GraphQLList(new GraphQLNonNull(GraphQLInt)))
  #   ).to.equal("[Int!]");
  #   expect(
  #     String(new GraphQLList(new GraphQLList(GraphQLInt)))
  #   ).to.equal("[[Int]]");
  # });

  # it("identifies input types", fn -> {
  #   const expected = [
  #     [ GraphQLInt, true ],
  #     [ ObjectType, false ],
  #     [ InterfaceType, false ],
  #     [ UnionType, false ],
  #     [ EnumType, true ],
  #     [ InputObjectType, true ]
  #   ];
  #   expected.forEach(([ type, answer ]) => {
  #     expect(isInputType(type)).to.equal(answer);
  #     expect(isInputType(new GraphQLList(type))).to.equal(answer);
  #     expect(isInputType(new GraphQLNonNull(type))).to.equal(answer);
  #   });
  # });

  # it("identifies output types", fn -> {
  #   const expected = [
  #     [ GraphQLInt, true ],
  #     [ ObjectType, true ],
  #     [ InterfaceType, true ],
  #     [ UnionType, true ],
  #     [ EnumType, true ],
  #     [ InputObjectType, false ]
  #   ];
  #   expected.forEach(([ type, answer ]) => {
  #     expect(isOutputType(type)).to.equal(answer);
  #     expect(isOutputType(new GraphQLList(type))).to.equal(answer);
  #     expect(isOutputType(new GraphQLNonNull(type))).to.equal(answer);
  #   });
  # });

  # it("prohibits nesting NonNull inside NonNull", fn -> {
  #   expect(fn ->
  #     new GraphQLNonNull(new GraphQLNonNull(GraphQLInt))
  #   ).to.throw(
  #     "Can only create NonNull of a Nullable GraphQLType but got: Int!."
  #   );
  # });

  # it("prohibits putting non-Object types in unions", fn -> {
  #   const badUnionTypes = [
  #     GraphQLInt,
  #     new GraphQLNonNull(GraphQLInt),
  #     new GraphQLList(GraphQLInt),
  #     InterfaceType,
  #     UnionType,
  #     EnumType,
  #     InputObjectType
  #   ];
  #   badUnionTypes.forEach(x => {
  #     expect(fn ->
  #       new GraphQLUnionType({ name: "BadUnion", types: [ x ] })
  #     ).to.throw(
  #       `BadUnion may only contain Object types, it cannot contain: ${x}.`
  #     );
  #   });
  # });

  # it("does not mutate passed field definitions", fn -> {
  #   const fields = {
  #     field1: {
  #       type: GraphQLString,
  #     },
  #     field2: {
  #       type: GraphQLString,
  #       args: {
  #         id: {
  #           type: GraphQLString
  #         }
  #       }
  #     }
  #   };
  #   const testObject1 = new GraphQLObjectType({
  #     name: "Test1",
  #     fields,
  #   });
  #   const testObject2 = new GraphQLObjectType({
  #     name: "Test2",
  #     fields,
  #   });

  #   expect(testObject1.getFields()).to.deep.equal(testObject2.getFields());
  #   expect(fields).to.deep.equal({
  #     field1: {
  #       type: GraphQLString,
  #     },
  #     field2: {
  #       type: GraphQLString,
  #       args: {
  #         id: {
  #           type: GraphQLString
  #         }
  #       }
  #     }
  #   });

  #   const testInputObject1 = new GraphQLInputObjectType({
  #     name: "Test1",
  #     fields
  #   });
  #   const testInputObject2 = new GraphQLInputObjectType({
  #     name: "Test2",
  #     fields
  #   });

  #   expect(testInputObject1.getFields()).to.deep.equal(
  #     testInputObject2.getFields()
  #   );
  #   expect(fields).to.deep.equal({
  #     field1: {
  #       type: GraphQLString,
  #     },
  #     field2: {
  #       type: GraphQLString,
  #       args: {
  #         id: {
  #           type: GraphQLString
  #         }
  #       }
  #     }
  #   });
  # });


end
