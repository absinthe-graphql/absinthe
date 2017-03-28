# defmodule Absinthe.Pipeline.BatchTest do
#   use Absinthe.Case, async: true
#
#   defmodule Store do
#
#   end
#
#   defmodule Schema do
#     use Absinthe.Schema
#
#     defp lookup_things(pid, ids) do
#       Store.lookup_things(pid, ids)
#     end
#
#     object :thing do
#       field :name, :string do
#         resolve fn parent_id, _, %{context: pid} ->
#           # the pid is of an agent that will make it easy to count
#           # accesses
#           batch({__MODULE__, :lookup_things, pid}, parent_id, fn results ->
#             {:ok, Map.get(results, parent_id)}
#           end)
#         end
#       end
#     end
#
#     query do
#       field :things, list_of(:thing) do
#         resolve fn _, _ ->
#           ids = [1,2,3]
#           {:ok, ids}
#         end
#       end
#     end
#   end
#
#   describe "batch" do
#     it "should work" do
#
#     end
#   end
# end
