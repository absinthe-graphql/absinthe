{
  :ok,
  %{
    data: %{"failingThing" => nil},
    errors: [
      %{
        code: 42,
        message: "Custom Error",
        path: ["failingThing"]
      }
    ]
  }
}
