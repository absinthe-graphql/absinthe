[
  {
    [operation_name: "ThingFoo"],
    {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}}
  },
  {
    [],
    {:ok,
     %{
       errors: [
         %{message: "Must provide a valid operation name if query contains multiple operations."}
       ]
     }}
  },
  {
    [operation_name: "invalid"],
    {:ok,
     %{
       errors: [
         %{message: "Must provide a valid operation name if query contains multiple operations."}
       ]
     }}
  }
]
