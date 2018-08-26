{:ok,
 %{
   data: %{
     "__schema" => %{
       "directives" => [
         %{
           "args" => [
             %{
               "name" => "if",
               "type" => %{
                 "kind" => "NON_NULL",
                 "ofType" => %{"kind" => "SCALAR", "name" => "Boolean"}
               }
             }
           ],
           "name" => "include",
           "locations" => ["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
           "onField" => true,
           "onFragment" => true,
           "onOperation" => false
         },
         %{
           "args" => [
             %{
               "name" => "if",
               "type" => %{
                 "kind" => "NON_NULL",
                 "ofType" => %{"kind" => "SCALAR", "name" => "Boolean"}
               }
             }
           ],
           "name" => "skip",
           "locations" => ["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
           "onField" => true,
           "onFragment" => true,
           "onOperation" => false
         }
       ]
     }
   }
 }}
