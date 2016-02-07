defmodule Absinthe.Type.DirectiveTest do
  use ExSpec, async: true

  alias Absinthe.Schema

  defmodule TestSchema do
    use Absinthe.Schema

    query [
      fields: [
        nonce: [type: :string]
      ]
    ]

  end

  describe "directives" do
    it "are loaded as built-ins" do
      assert %{skip: "skip", include: "include"} = TestSchema.__absinthe_directives__
      assert TestSchema.__absinthe_directive__(:skip)
      assert TestSchema.__absinthe_directive__("skip") == TestSchema.__absinthe_directive__(:skip)
      assert Schema.lookup_directive(TestSchema, :skip) == TestSchema.__absinthe_directive__(:skip)
      assert Schema.lookup_directive(TestSchema, "skip") == TestSchema.__absinthe_directive__(:skip)
    end

  end

end
