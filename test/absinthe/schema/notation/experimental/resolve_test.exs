defmodule Absinthe.Schema.Notation.Experimental.ResolveTest do
  use Absinthe.Case, async: true
  import ExperimentalNotationHelpers

  @moduletag :experimental

  defmodule Definition do
    use Absinthe.Schema.Notation

    object :obj do
      field :anon_literal, :boolean do
        resolve fn _, _, _ ->
          {:ok, true}
        end
      end

      field :local_private, :boolean do
        resolve &local_private/3
      end

      field :local_public, :boolean do
        resolve &local_public/3
      end

      field :remote, :boolean do
        resolve &Absinthe.Schema.Notation.Experimental.ResolveTest.remote_resolve/3
      end

      field :remote_ref, :boolean do
        resolve {Absinthe.Schema.Notation.Experimental.ResolveTest, :remote_resolve}
      end

      field :invocation_result, :boolean do
        resolve mapping(:foo)
      end
    end

    defp local_private(_, _, _) do
      {:ok, true}
    end

    def local_public(_, _, _) do
      {:ok, true}
    end

    def mapping(_) do
      fn _, _, _ ->
        {:ok, true}
      end
    end
  end

  def remote_resolve(_, _, _) do
    {:ok, true}
  end

  def assert_resolver(field_identifier) do
    assert %{middleware: [{:ref, module, identifier}]} =
             lookup_field(Definition, :obj, field_identifier)

    assert [{{Absinthe.Resolution, :call}, _}] =
             module.__absinthe_function__(identifier, :middleware)
  end

  describe "resolve" do
    test "when given an anonymous function literal" do
      assert_resolver(:anon_literal)
    end

    test "when given a local private function capture" do
      assert_resolver(:local_private)
    end

    test "when given a local public function capture" do
      assert_resolver(:local_public)
    end

    test "when given a remote public function capture" do
      assert_resolver(:remote)
    end

    test "when given a remote ref" do
      assert_resolver(:remote_ref)
    end

    test "when given the result of a function invocation" do
      assert_resolver(:invocation_result)
    end
  end
end
