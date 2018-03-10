defmodule Absinthe.Schema.Rule.DefaultEnumValuePresentTest do
  use Absinthe.Case, async: true

  describe "rule" do
    test "is enforced when the defaultValue is not in the enum" do
      schema = """
      defmodule BadColorSchema do
        use Absinthe.Schema

        @names %{
          r: "RED"
        }

        query do

          field :info,
          type: :channel_info,
          args: [
            channel: [type: non_null(:channel), default_value: :OTHER],
          ],
          resolve: fn
            %{channel: channel}, _ ->
            {:ok, %{name: @names[channel]}}
          end

        end

        enum :channel do
          value :red, as: :r
          value :green, as: :g
        end

        object :channel_info do
          field :name, :string
        end
      end
      """

      error = ~r/The default_value for an enum must be present in the enum values/

      assert_raise(Absinthe.Schema.Error, error, fn ->
        Code.eval_string(schema)
      end)
    end
  end
end
