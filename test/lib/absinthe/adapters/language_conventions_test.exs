defmodule Absinthe.Adapter.LanguageConventionsTest do
  use Absinthe.Case, async: true

  alias Absinthe.Adapter.LanguageConventions

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

  defmodule Simple do

    use Absinthe.Schema

    @db %{
      "museum" => %{id: "museum", name: "Museum", location_name: "Portland"},
      "opera_house" => %{id: "opera_house", name: "Opera House", location_name: "Sydney"}
    }

    query do

      field :bad_resolution,
        type: :field_trip,
        resolve: fn
          _, _ ->
            :not_expected
        end

      field :field_trip_by_context,
        type: :field_trip,
        resolve: fn
          _, %{context: %{field_trip: id}} ->
            {:ok, @db |> Map.get(id)}
          _, _ ->
            {:error, "No :id context provided"}
        end

      field :field_trip,
        type: :field_trip,
        args: [
          id: [
            description: "id of the field trip",
            type: non_null(:string)
          ]
        ],
        resolve: fn
          %{id: id}, _ ->
            {:ok, @db |> Map.get(id)}
        end

      field :field_trips,
        type: list_of(:field_trip),
        args: [
          location: [
            description: "nested location object",
            type: :input_location
          ],
          location_name: [
            description: "The location of the field trip",
            type: :string
          ]
        ],
        resolve: fn
          %{location_name: name}, _ ->
            {:ok, find_trips(name)}
          %{location: %{name: name}}, _ ->
            {:ok, find_trips(name)}
        end

    end

    input_object :input_location do
      description "A location"
      field :name, non_null(:string)
    end

    object :field_trip do
      description "A field trip"

      field :id,
        type: non_null(:string),
        description: "The ID of the field trip"

      field :name,
        type: :string,
        description: "The name of field trip is located"

      field :location_name,
        type: :string,
        description: "The place the field trip is located"

      field :other_field_trip,
        type: :field_trip,
        resolve: fn
          _, %{resolution: %{target: %{id: "museum"}}} ->
            {:ok, @db |> Map.get("opera_house")}
          _, %{resolution: %{target: %{id: "opera_house"}}} ->
              {:ok, @db |> Map.get("museum")}
        end

    end

    defp find_trips(name) do
      for {_, %{location_name: location} = ft} <- @db, location == name, into: []  do
        ft
      end
    end

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
    assert {:ok, %{data: %{"fieldTrip" => %{"name" => "Museum", "locationName" => "Portland"}}}} == run(query)
  end


  it "can do a query with an object argument" do
    query = """
    query GimmeMuseum {
      fieldTrips(location: {name: "Portland", foo: "buzz"}) {
        name
        locationName
      }
    }
    """
    assert {:ok, %{data: %{"fieldTrips" => [%{"name" => "Museum", "locationName" => "Portland"}]}, errors: [%{locations: [], message: "Argument `location.foo': Not present in schema"}]}} == run(query)
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
    assert {:ok, %{data: %{"fieldTrip" => %{"name" => "Museum", "locationName" => "Portland"}}}} == run(query, %{"myId" => "museum"})
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
    assert {:ok, %{data: %{"fieldTrips" => [%{"name" => "Museum", "locationName" => "Portland"}]}}} == run(query)
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
    assert {:ok, %{data: %{"thePlace" => %{"name" => "Museum", "locationName" => "Portland"}}}} == run(query)
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
    assert {:ok, %{data: %{"fieldTrip" => %{"name" => "Museum"}}, errors: [%{message: "Field `badField': Not present in schema", locations: [%{line: 4, column: 0}]}]}} == run(query)
  end

  it "transforms a simple query document" do
    doc = transform """
    {
      person {
        firstName
      }
    }
    """
    assert %{definitions: [%{selection_set: %{selections: [%{selection_set: %{selections: [%{name: "first_name"}]}}]}}]} = doc
  end

  it "transforms a query document with an inline fragment" do
    doc = transform """
    {
      person {
       ... on Foo {
         firstName
       }
      }
    }
    """
    assert %{definitions: [%{selection_set: %{selections: [%{selection_set: %{selections: [%{selection_set: %{selections: [%{name: "first_name"}]}}]}}]}}]} = doc
  end

  defp transform(query) do
    {:ok, doc} = Absinthe.parse(query)
    doc
    |> Absinthe.Adapter.LanguageConventions.load_document
  end

  defp run(query_document) do
    run(query_document, %{})
  end
  defp run(query_document, variables) do
    Absinthe.run(query_document, Simple,
                  validate: false, variables: variables, adapter: LanguageConventions)
  end


end
