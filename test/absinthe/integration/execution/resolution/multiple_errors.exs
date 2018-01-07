{
  :ok,
  %{
    data: %{"failingThing" => nil},
    errors: [
      %{message: "one", path: ["failingThing"]},
      %{message: "two", path: ["failingThing"]}
    ]
  }
}
