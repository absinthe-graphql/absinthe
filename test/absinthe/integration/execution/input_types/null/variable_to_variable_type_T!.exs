[
  # Passed, causes error
  {[variables: %{"mult" => nil}],
   {:ok, %{errors: [%{message: "Variable \"mult\": Expected non-null, found null."}]}}},
  # Not passed, causes error
  {:ok, %{errors: [%{message: "Variable \"mult\": Expected non-null, found null."}]}},
  # Control
  {[variables: %{"mult" => 2}], {:ok, %{data: %{"times" => 8}}}}
]
