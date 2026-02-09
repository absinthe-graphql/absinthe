defmodule Absinthe.Schema.Coordinate.ErrorHelpers do
  @moduledoc """
  Helper functions for including schema coordinates in error messages.

  These helpers make it easy to include precise schema coordinate references
  in error messages, improving debuggability and tooling integration.

  ## Usage

      import Absinthe.Schema.Coordinate.ErrorHelpers

      # In an error message
      "Field #{coordinate_for(type, field)} is deprecated"

      # Adding coordinate to error extras
      error
      |> put_coordinate(type, field)
  """

  alias Absinthe.Schema.Coordinate

  @doc """
  Generate a coordinate string for a schema element.

  Accepts various combinations of arguments to generate the appropriate coordinate.

  ## Examples

      coordinate_for("User")
      # => "User"

      coordinate_for("User", "email")
      # => "User.email"

      coordinate_for("Query", "user", "id")
      # => "Query.user(id:)"

      coordinate_for(:directive, "deprecated")
      # => "@deprecated"

      coordinate_for(:directive, "deprecated", "reason")
      # => "@deprecated(reason:)"
  """
  @spec coordinate_for(String.t() | atom()) :: String.t()
  def coordinate_for(type_name) do
    Coordinate.for_type(type_name)
  end

  @spec coordinate_for(String.t(), String.t()) :: String.t()
  def coordinate_for(type_name, field_name) do
    Coordinate.for_field(to_string(type_name), to_string(field_name))
  end

  @spec coordinate_for(:directive, String.t()) :: String.t()
  def coordinate_for(:directive, directive_name) do
    Coordinate.for_directive(to_string(directive_name))
  end

  @spec coordinate_for(String.t(), String.t(), String.t()) :: String.t()
  def coordinate_for(type_name, field_name, arg_name) do
    Coordinate.for_argument(to_string(type_name), to_string(field_name), to_string(arg_name))
  end

  @spec coordinate_for(:directive, String.t(), String.t()) :: String.t()
  def coordinate_for(:directive, directive_name, arg_name) do
    Coordinate.for_directive_argument(to_string(directive_name), to_string(arg_name))
  end

  @doc """
  Add a schema coordinate to an error's extra data.

  This is useful when building Absinthe errors and you want to include
  the coordinate for tooling or debugging purposes.

  ## Examples

      %{message: "Field is deprecated"}
      |> put_coordinate("User", "oldField")
      # => %{message: "Field is deprecated", coordinate: "User.oldField"}
  """
  @spec put_coordinate(map(), String.t() | atom()) :: map()
  def put_coordinate(error, type_name) do
    Map.put(error, :coordinate, coordinate_for(type_name))
  end

  @spec put_coordinate(map(), String.t(), String.t()) :: map()
  def put_coordinate(error, type_name, field_name) do
    Map.put(error, :coordinate, coordinate_for(type_name, field_name))
  end

  @spec put_coordinate(map(), String.t(), String.t(), String.t()) :: map()
  def put_coordinate(error, type_name, field_name, arg_name) do
    Map.put(error, :coordinate, coordinate_for(type_name, field_name, arg_name))
  end

  @doc """
  Format an error message with a coordinate prefix.

  ## Examples

      with_coordinate("is deprecated", "User", "oldField")
      # => "[User.oldField] is deprecated"
  """
  @spec with_coordinate(String.t(), String.t() | atom()) :: String.t()
  def with_coordinate(message, type_name) do
    "[#{coordinate_for(type_name)}] #{message}"
  end

  @spec with_coordinate(String.t(), String.t(), String.t()) :: String.t()
  def with_coordinate(message, type_name, field_name) do
    "[#{coordinate_for(type_name, field_name)}] #{message}"
  end

  @spec with_coordinate(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def with_coordinate(message, type_name, field_name, arg_name) do
    "[#{coordinate_for(type_name, field_name, arg_name)}] #{message}"
  end
end
