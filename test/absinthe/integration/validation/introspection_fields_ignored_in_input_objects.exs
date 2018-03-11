{
  [variables: %{"input" => %{"value" => 100, "__typename" => "foo"}}],
  {:ok,
   %{
     errors: [
       %{
         message:
           "Argument \"thing\" has invalid value $input.\nIn field \"__typename\": Unknown field."
       }
     ]
   }}
}
