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
           "locations" => ["INLINE_FRAGMENT", "FRAGMENT_SPREAD", "FIELD"],
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
           "locations" => ["INLINE_FRAGMENT", "FRAGMENT_SPREAD", "FIELD"],
           "onField" => true,
           "onFragment" => true,
           "onOperation" => false
         }
       ]
     }
   }
 }}
