{:ok,
 %{
   data: %{"failingThing" => nil},
   errors: [
     %{code: 1, message: "Custom Error 1", path: ["failingThing"]},
     %{code: 2, message: "Custom Error 2", path: ["failingThing"]}
   ]
 }}
