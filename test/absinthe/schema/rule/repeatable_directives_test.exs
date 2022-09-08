defmodule Absinthe.Schema.Rule.RepeatedDirectivesTest do
  use Absinthe.Case, async: true
  import ExperimentalNotationHelpers

  @invalid_repeated_directives_macro ~s"""
  defmodule InvalidRepeatedDirectiveMacro do
    use Absinthe.Schema

    query do
    end

    object :dog do
      field :name, :string do
        deprecate()
        deprecate()
      end
    end
  end
  """

  test "errors on invalid repeated directive on macro schemas" do
    error = ~r/Directive `deprecated' cannot be applied repeatedly./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@invalid_repeated_directives_macro)
    end)
  end

  @invalid_repeated_directives_sdl ~s(
  defmodule InvalidRepeatedDirectiveSdl do
    use Absinthe.Schema

    query do
    end

    import_sdl ~s"""
      type Dog {
        name: String @deprecated @deprecated
      }
    """
  end
  )

  test "errors on invalid repeated directive on sdl schemas" do
    error = ~r/Directive `deprecated' cannot be applied repeatedly./

    assert_raise(Absinthe.Schema.Error, error, fn ->
      Code.eval_string(@invalid_repeated_directives_sdl)
    end)
  end

  defmodule WithFeatureDirective do
    use Absinthe.Schema.Prototype

    directive :feature do
      on [:field_definition]
      repeatable true
    end
  end

  defmodule ValidRepeatedDirectiveMacro do
    use Absinthe.Schema

    @prototype_schema WithFeatureDirective

    query do
      field :foo, :string
    end

    object :dog do
      field :name, :string do
        directive :feature
        directive :feature
      end
    end
  end

  test "does not raise with repeated directive on macro schemas" do
    assert %{directives: [%{name: "feature"}, %{name: "feature"}]} =
             lookup_field(ValidRepeatedDirectiveMacro, :dog, :name)
  end

  defmodule ValidRepeatedDirectiveSdl do
    use Absinthe.Schema

    @prototype_schema WithFeatureDirective

    query do
      field :foo, :string
    end

    import_sdl ~s"""
      type Dog {
        name: String @feature @feature
      }
    """
  end

  test "does not raise with repeated directive on sdl schemas" do
    assert %{directives: [%{name: "feature"}, %{name: "feature"}]} =
             lookup_field(ValidRepeatedDirectiveSdl, :dog, :name)
  end
end
