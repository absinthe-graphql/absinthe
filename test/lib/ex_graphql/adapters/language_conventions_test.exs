defmodule ExGraphQL.Adapters.LanguageConventionsTest do
  use ExSpec, async: true

  use ExGraphQL.Type
  alias ExGraphQL.Type
  alias ExGraphQL.Adapters.LanguageConventions

  it "converts external camelcase field names to underscore" do
    assert "foo_bar" = LanguageConventions.to_internal_name("fooBar", :field)
  end
  it "converts external camelcase variable names to underscore" do
    assert "foo_bar" = LanguageConventions.to_internal_name("fooBar", :variable)
  end

  it "converts internal underscored field names to camelcase external field names" do
    assert "fooBar" = LanguageConventions.to_external_name("foo_bar", :field)
  end
  it "converts internal underscored variable names to camelcase external variable names" do
    assert "fooBar" = LanguageConventions.to_external_name("foo_bar", :variable)
  end

  defp field_trip_type do
    %Type.ObjectType{
      name: "FieldTrip",
      description: "A field_trip",
      fields: fields(
        id: [
          type: %Type.NonNull{of_type: Type.Scalar.string},
          description: "The ID of the field trip"
        ],
        name: [
          type: Type.Scalar.string,
          description: "The name of field trip is located"
        ],
        location_name: [
          type: Type.Scalar.string,
          description: "The place the field trip is located"
        ],
        other_field_trip: [
          type: field_trip_type,
          resolve: fn (_, %{resolution: %{target: %{id: id}}}) ->
            case id do
              "museum" -> {:ok, field_trips |> Map.get("opera_house")}
              "opera_house" -> {:ok, field_trips |> Map.get("museum")}
            end
          end
        ]
      )
    }
  end

  defp field_trips do
    %{
      "museum" => %{id: "museum", name: "Museum", location_name: "Portland"},
      "opera_house" => %{id: "opera_house", name: "Opera House", location_name: "Sydney"}
     }
  end

  defp simple_schema do
    %Type.Schema{
      query: %Type.ObjectType{
        name: "RootQuery",
        fields: fields(
          bad_resolution: [
            type: field_trip_type,
            resolve: fn(_, _) ->
              :not_expected
            end
          ],
          field_trip_by_context: [
            type: field_trip_type,
            resolve: fn
              (_, %{context: %{field_trip: id}}) -> {:ok, field_trips |> Map.get(id)}
              (_, _) -> {:error, "No :id context provided"}
            end
          ],
          field_trip: [
            type: field_trip_type,
            args: args(
              id: [
                description: "id of the field trip",
                type: non_null(Type.Scalar.string)
              ]
            ),
            resolve: fn
              (%{"id" => id}, _) ->
                {:ok, field_trips |> Map.get(id)}
            end
          ],
          field_trips: [
            type: list_of(field_trip_type),
            args: args(
              location_name: [
                description: "The location of the field trip",
                type: Type.Scalar.string
              ]
            ),
            resolve: fn (%{"location_name" => loc}, _) ->
              results = for {_, %{location_name: location} = ft} <- field_trips, location == loc, into: []  do
                ft
              end
              {:ok, results}
            end
          ]
        )
      }
    }
  end

  it "can do a simple query" do
    query = """
    query GimmeMuseum {
      fieldTrip(id: "museum") {
        name
        locationName
      }
    }
    """
    assert {:ok, %{data: %{"fieldTrip" => %{"name" => "Museum", "locationName" => "Portland"}}, errors: []}} = run(query)
  end

  it "can do a simple query with an adapted variable" do
    query = """
      query GimmeMuseumWithVariable($myId: String!) {
        fieldTrip(id: $myId) {
          name
          locationName
        }
      }
    """
    assert {:ok, %{data: %{"fieldTrip" => %{"name" => "Museum", "locationName" => "Portland"}}, errors: []}} = run(query, %{myId: "museum"})
  end

  it "can do a simple query with an adapted argument" do
    query = """
      query GimmeMuseumByLocationName {
        fieldTrips(locationName: "Portland") {
          name
          locationName
        }
      }
    """
    assert {:ok, %{data: %{"fieldTrips" => [%{"name" => "Museum", "locationName" => "Portland"}]}, errors: []}} = run(query)
  end


  it "can do a simple query with an alias" do
    query = """
      query GimmeMuseumWithAlias {
        thePlace: fieldTrip(id: "museum") {
          name
          locationName
        }
      }
    """
    assert {:ok, %{data: %{"thePlace" => %{"name" => "Museum", "locationName" => "Portland"}}, errors: []}} = run(query)
  end


  it "can identify a bad field" do
    query = """
    {
      fieldTrip(id: "museum") {
        name
        badField
      }
    }
    """
    assert {:ok, %{data: %{"fieldTrip" => %{"name" => "Museum"}}, errors: [%{message: "Field `badField': Not present in schema", locations: [%{line: 4, column: 0}]}]}} = run(query)
  end

  defp run(query_document) do
    run(query_document, %{})
  end
  defp run(query_document, variables) do
    ExGraphQL.run(simple_schema, query_document,
                  validate: false, variables: variables, adapter: LanguageConventions)
  end


end
