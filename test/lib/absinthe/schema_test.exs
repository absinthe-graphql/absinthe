defmodule Absinthe.SchemaTest do
  use ExSpec, async: true

  describe "verify/1" do

    describe "given a good schema" do

      it 'returns :ok' do
        assert :ok == Absinthe.Schema.verify(Things)
        assert :ok == Absinthe.Schema.verify(Things.schema)
      end

    end

    describe "given a bad schema" do

      it 'returns a tuple with the errors' do
        bad = %{Things.schema | errors: ["oops"]}
        assert {:error, ["oops"]} = Absinthe.Schema.verify(bad)
      end

    end

  end
end
