{:ok,
 %{
   data: %{"things" => [%{"id" => "bar", "fail" => "bar"}, %{"id" => "foo", "fail" => nil}]},
   errors: [%{message: "fail", path: ["things", 1, "fail"]}]
 }}
