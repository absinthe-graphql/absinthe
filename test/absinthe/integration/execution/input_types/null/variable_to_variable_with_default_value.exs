[
  # Not provided, retains default
  {:ok, %{data: %{"times" => 24}}},
  # Provided, overrides default
  {[variables: %{"mult" => nil}], {:ok, %{data: %{"times" => 4}}}}
]
