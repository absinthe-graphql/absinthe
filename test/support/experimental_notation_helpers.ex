defmodule ExperimentalNotationHelpers do
  alias Absinthe.Blueprint

  def lookup_type(mod, type_ident) do
    Blueprint.Schema.lookup_type(mod.__absinthe_blueprint__(), type_ident)
  end

  def lookup_directive(mod, directive_ident) do
    Blueprint.Schema.lookup_directive(mod.__absinthe_blueprint__(), directive_ident)
  end

  def lookup_compiled_type(mod, type_ident) do
    Absinthe.Schema.lookup_type(mod, type_ident)
  end

  def lookup_compiled_directive(mod, directive_ident) do
    Absinthe.Schema.lookup_directive(mod, directive_ident)
  end

  def lookup_field(mod, type_ident, field_ident) do
    type = Blueprint.Schema.lookup_type(mod.__absinthe_blueprint__(), type_ident)

    Enum.find(type.fields, fn
      %{identifier: ^field_ident} ->
        true

      _ ->
        false
    end)
  end

  def lookup_argument(mod, type_ident, field_ident, arg_ident) do
    case lookup_field(mod, type_ident, field_ident) do
      nil ->
        nil

      field ->
        Enum.find(field.arguments, fn
          %{identifier: ^arg_ident} ->
            true

          _ ->
            false
        end)
    end
  end

  def lookup_compiled_field(mod, type_ident, field_ident) do
    case Absinthe.Schema.lookup_type(mod, type_ident) do
      nil ->
        nil

      type ->
        type.fields[field_ident]
    end
  end

  def lookup_compiled_argument(mod, type_ident, field_ident, arg_ident) do
    case lookup_compiled_field(mod, type_ident, field_ident) do
      nil ->
        nil

      field ->
        field.args[arg_ident]
    end
  end

  def type_count(mod) do
    mod.__absinthe_blueprint__().schema_definitions
    |> List.first()
    |> Map.fetch!(:types)
    |> length
  end
end
