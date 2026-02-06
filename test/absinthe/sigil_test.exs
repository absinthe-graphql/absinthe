defmodule Absinthe.SigilTest do
  use Absinthe.Case, async: true
  import ExUnit.CaptureIO

  test "~GQL sigil formatting" do
    assert ~GQL"{version}" == "{\n  version\n}\n"
  end

  test "~GQL sigil validation error reporting" do
    this_file = __ENV__.file |> String.split("/") |> List.last()
    # ENV gives full path, but error message is relative path

    err_out =
      capture_io(:stderr, fn ->
        assert ~GQL"{version" == "{version"
      end)

    assert err_out =~ "~GQL sigil validation error"
    assert err_out =~ this_file
    assert err_out =~ "syntax error"

    err_out =
      capture_io(:stderr, fn ->
        assert ~GQL"query { item(this-won't-lex) }" == "query { item(this-won't-lex) }"
      end)

    assert err_out =~ "~GQL sigil validation error"
    assert err_out =~ this_file
    assert err_out =~ "Parsing failed at `-won't-lex`"
  end
end
