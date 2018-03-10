[
  {[variables: %{"value" => nil}],
   {:ok,
    %{
      errors: [
        %{
          message:
            "Argument \"input\" has invalid value {base: $value}.\nIn field \"base\": Expected type \"Int!\", found $value."
        },
        %{message: "Variable \"value\": Expected non-null, found null."}
      ]
    }}},
  {[variables: %{"value" => 8}], {:ok, %{data: %{"times" => 16}}}}
]
