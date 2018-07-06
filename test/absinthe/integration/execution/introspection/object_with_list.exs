{:ok,
 %{
   data: %{
     "__type" => %{
       "fields" => [
         %{
           "name" => "address",
           "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}
         },
         %{"name" => "age", "type" => %{"kind" => "SCALAR", "name" => "Int", "ofType" => nil}},
         %{
           "name" => "name",
           "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}
         },
         %{
           "name" => "others",
           "type" => %{
             "kind" => "LIST",
             "name" => nil,
             "ofType" => %{"kind" => "OBJECT", "name" => "Person"}
           }
         }
       ]
     }
   }
 }}
