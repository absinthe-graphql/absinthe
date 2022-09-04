defmodule Absinthe.Phase.Schema.SpecCompliantInt.Test do
  use Absinthe.Case, async: true

  defmodule SchemaWithSpecComplientIntPipelineModifier do
    use Absinthe.Schema

    @pipeline_modifier Absinthe.Phase.Schema.SpecCompliantInt

    query do
      field :parse, :integer do
        arg :input, :integer

        resolve fn args, _ ->
          {:ok, args[:input]}
        end
      end
    end
  end

  defmodule SchemaWithSpecComplientOption do
    use Absinthe.Schema, use_spec_compliant_int_scalar: true

    query do
      field :parse, :integer do
        arg :input, :integer

        resolve fn args, _ ->
          {:ok, args[:input]}
        end
      end
    end
  end

  @query "query ($input: Int!) { parse(input: $input) }"
  @min_int -2_147_483_648
  @max_int 2_147_483_647

  defp assert_int_valid(schema, int_value) do
    assert {
             :ok,
             %{
               data: %{"parse" => int_value}
             }
           } ==
             Absinthe.run(
               @query,
               schema,
               variables: %{
                 "input" => int_value
               }
             )
  end

  defp assert_int_invalid(schema, int_value) do
    assert {
             :ok,
             %{
               errors: [
                 %{
                   message: "Argument \"input\" has invalid value $input.",
                   locations: [%{column: 30, line: 1}]
                 }
               ]
             }
           } ==
             Absinthe.run(
               @query,
               schema,
               variables: %{
                 "input" => int_value
               }
             )
  end

  describe "overriding built-in Int type with SpecCompliantInt (pipeline modifier)" do
    test "minimum valid int" do
      assert_int_valid(SchemaWithSpecComplientIntPipelineModifier, @min_int)
    end

    test "maximum valid int" do
      assert_int_valid(SchemaWithSpecComplientIntPipelineModifier, @max_int)
    end

    test "value outside lower bound" do
      assert_int_invalid(SchemaWithSpecComplientIntPipelineModifier, @min_int - 1)
    end

    test "value outside upper bound" do
      assert_int_invalid(SchemaWithSpecComplientIntPipelineModifier, @max_int + 1)
    end
  end

  describe "overriding built-in Int type with SpecCompliantInt (Schema option)" do
    test "minimum valid int" do
      assert_int_valid(SchemaWithSpecComplientOption, @min_int)
    end

    test "maximum valid int" do
      assert_int_valid(SchemaWithSpecComplientOption, @max_int)
    end

    test "value outside lower bound" do
      assert_int_invalid(SchemaWithSpecComplientOption, @min_int - 1)
    end

    test "value outside upper bound" do
      assert_int_invalid(SchemaWithSpecComplientOption, @max_int + 1)
    end
  end
end
