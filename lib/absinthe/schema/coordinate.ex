defmodule Absinthe.Schema.Coordinate do
  @moduledoc """
  Schema Coordinates as defined in the GraphQL specification.

  Schema coordinates provide a standardized, human-readable format for
  referencing elements within a GraphQL schema. Each schema element can
  be uniquely identified by exactly one coordinate.

  ## Coordinate Formats

  | Element Type | Format | Example |
  |--------------|--------|---------|
  | Type | `TypeName` | `User` |
  | Field | `TypeName.fieldName` | `User.email` |
  | Field Argument | `TypeName.fieldName(argName:)` | `Query.user(id:)` |
  | Enum Value | `EnumName.VALUE` | `Status.ACTIVE` |
  | Input Field | `InputTypeName.fieldName` | `CreateUserInput.email` |
  | Directive | `@directiveName` | `@deprecated` |
  | Directive Argument | `@directiveName(argName:)` | `@deprecated(reason:)` |

  ## Usage

      # Generate coordinates
      Absinthe.Schema.Coordinate.for_type("User")
      # => "User"

      Absinthe.Schema.Coordinate.for_field("User", "email")
      # => "User.email"

      Absinthe.Schema.Coordinate.for_argument("Query", "user", "id")
      # => "Query.user(id:)"

      # Parse coordinates
      Absinthe.Schema.Coordinate.parse("User.email")
      # => {:ok, {:field, "User", "email"}}

      # Resolve coordinates against a schema
      Absinthe.Schema.Coordinate.resolve(MySchema, "User.email")
      # => {:ok, %Absinthe.Type.Field{...}}

  ## References

  - [GraphQL Spec: Schema Coordinates](https://spec.graphql.org/draft/#sec-Schema-Coordinates)
  - [RFC #794](https://github.com/graphql/graphql-spec/pull/794)
  """

  @type coordinate :: String.t()

  @type parsed_coordinate ::
          {:type, type_name :: String.t()}
          | {:field, type_name :: String.t(), field_name :: String.t()}
          | {:argument, type_name :: String.t(), field_name :: String.t(), arg_name :: String.t()}
          | {:enum_value, enum_name :: String.t(), value_name :: String.t()}
          | {:input_field, type_name :: String.t(), field_name :: String.t()}
          | {:directive, directive_name :: String.t()}
          | {:directive_argument, directive_name :: String.t(), arg_name :: String.t()}

  # Regex patterns for parsing coordinates
  @type_pattern ~r/^([A-Za-z_][A-Za-z0-9_]*)$/
  @field_pattern ~r/^([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)$/
  @argument_pattern ~r/^([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\(([A-Za-z_][A-Za-z0-9_]*):\)$/
  @directive_pattern ~r/^@([A-Za-z_][A-Za-z0-9_]*)$/
  @directive_arg_pattern ~r/^@([A-Za-z_][A-Za-z0-9_]*)\(([A-Za-z_][A-Za-z0-9_]*):\)$/

  # ============================================================================
  # Coordinate Generation
  # ============================================================================

  @doc """
  Generate a coordinate for a type.

  ## Examples

      iex> Absinthe.Schema.Coordinate.for_type("User")
      "User"

      iex> Absinthe.Schema.Coordinate.for_type(:user)
      "user"
  """
  @spec for_type(String.t() | atom()) :: coordinate()
  def for_type(type_name) when is_atom(type_name), do: Atom.to_string(type_name)
  def for_type(type_name) when is_binary(type_name), do: type_name

  @doc """
  Generate a coordinate for a field.

  ## Examples

      iex> Absinthe.Schema.Coordinate.for_field("User", "email")
      "User.email"
  """
  @spec for_field(String.t(), String.t()) :: coordinate()
  def for_field(type_name, field_name) do
    "#{type_name}.#{field_name}"
  end

  @doc """
  Generate a coordinate for a field argument.

  ## Examples

      iex> Absinthe.Schema.Coordinate.for_argument("Query", "user", "id")
      "Query.user(id:)"
  """
  @spec for_argument(String.t(), String.t(), String.t()) :: coordinate()
  def for_argument(type_name, field_name, arg_name) do
    "#{type_name}.#{field_name}(#{arg_name}:)"
  end

  @doc """
  Generate a coordinate for an enum value.

  ## Examples

      iex> Absinthe.Schema.Coordinate.for_enum_value("Status", "ACTIVE")
      "Status.ACTIVE"
  """
  @spec for_enum_value(String.t(), String.t()) :: coordinate()
  def for_enum_value(enum_name, value_name) do
    "#{enum_name}.#{value_name}"
  end

  @doc """
  Generate a coordinate for an input object field.

  ## Examples

      iex> Absinthe.Schema.Coordinate.for_input_field("CreateUserInput", "email")
      "CreateUserInput.email"
  """
  @spec for_input_field(String.t(), String.t()) :: coordinate()
  def for_input_field(type_name, field_name) do
    "#{type_name}.#{field_name}"
  end

  @doc """
  Generate a coordinate for a directive.

  ## Examples

      iex> Absinthe.Schema.Coordinate.for_directive("deprecated")
      "@deprecated"

      iex> Absinthe.Schema.Coordinate.for_directive("@skip")
      "@skip"
  """
  @spec for_directive(String.t()) :: coordinate()
  def for_directive("@" <> _ = directive_name), do: directive_name
  def for_directive(directive_name), do: "@#{directive_name}"

  @doc """
  Generate a coordinate for a directive argument.

  ## Examples

      iex> Absinthe.Schema.Coordinate.for_directive_argument("deprecated", "reason")
      "@deprecated(reason:)"
  """
  @spec for_directive_argument(String.t(), String.t()) :: coordinate()
  def for_directive_argument("@" <> directive_name, arg_name) do
    "@#{directive_name}(#{arg_name}:)"
  end

  def for_directive_argument(directive_name, arg_name) do
    "@#{directive_name}(#{arg_name}:)"
  end

  # ============================================================================
  # Coordinate Parsing
  # ============================================================================

  @doc """
  Parse a schema coordinate string into its component parts.

  Returns `{:ok, parsed}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> Absinthe.Schema.Coordinate.parse("User")
      {:ok, {:type, "User"}}

      iex> Absinthe.Schema.Coordinate.parse("User.email")
      {:ok, {:field, "User", "email"}}

      iex> Absinthe.Schema.Coordinate.parse("Query.user(id:)")
      {:ok, {:argument, "Query", "user", "id"}}

      iex> Absinthe.Schema.Coordinate.parse("@deprecated")
      {:ok, {:directive, "deprecated"}}

      iex> Absinthe.Schema.Coordinate.parse("@deprecated(reason:)")
      {:ok, {:directive_argument, "deprecated", "reason"}}

      iex> Absinthe.Schema.Coordinate.parse("invalid coordinate!")
      {:error, "Invalid schema coordinate: invalid coordinate!"}
  """
  @spec parse(coordinate()) :: {:ok, parsed_coordinate()} | {:error, String.t()}
  def parse(coordinate) when is_binary(coordinate) do
    coordinate = String.trim(coordinate)

    cond do
      # Directive argument: @name(arg:)
      match = Regex.run(@directive_arg_pattern, coordinate) ->
        [_, directive_name, arg_name] = match
        {:ok, {:directive_argument, directive_name, arg_name}}

      # Directive: @name
      match = Regex.run(@directive_pattern, coordinate) ->
        [_, directive_name] = match
        {:ok, {:directive, directive_name}}

      # Field argument: Type.field(arg:)
      match = Regex.run(@argument_pattern, coordinate) ->
        [_, type_name, field_name, arg_name] = match
        {:ok, {:argument, type_name, field_name, arg_name}}

      # Field: Type.field
      match = Regex.run(@field_pattern, coordinate) ->
        [_, type_name, field_name] = match
        {:ok, {:field, type_name, field_name}}

      # Type: TypeName
      match = Regex.run(@type_pattern, coordinate) ->
        [_, type_name] = match
        {:ok, {:type, type_name}}

      true ->
        {:error, "Invalid schema coordinate: #{coordinate}"}
    end
  end

  @doc """
  Parse a schema coordinate, raising on error.

  ## Examples

      iex> Absinthe.Schema.Coordinate.parse!("User.email")
      {:field, "User", "email"}
  """
  @spec parse!(coordinate()) :: parsed_coordinate()
  def parse!(coordinate) do
    case parse(coordinate) do
      {:ok, parsed} -> parsed
      {:error, message} -> raise ArgumentError, message
    end
  end

  # ============================================================================
  # Coordinate Resolution
  # ============================================================================

  @doc """
  Resolve a schema coordinate against a schema, returning the referenced element.

  ## Examples

      Absinthe.Schema.Coordinate.resolve(MySchema, "User")
      # => {:ok, %Absinthe.Type.Object{...}}

      Absinthe.Schema.Coordinate.resolve(MySchema, "User.email")
      # => {:ok, %Absinthe.Type.Field{...}}

      Absinthe.Schema.Coordinate.resolve(MySchema, "Query.user(id:)")
      # => {:ok, %Absinthe.Type.Argument{...}}

      Absinthe.Schema.Coordinate.resolve(MySchema, "NonExistent")
      # => {:error, "Type not found: NonExistent"}
  """
  @spec resolve(Absinthe.Schema.t(), coordinate()) ::
          {:ok, Absinthe.Type.t() | Absinthe.Type.Field.t() | Absinthe.Type.Argument.t()}
          | {:error, String.t()}
  def resolve(schema, coordinate) when is_atom(schema) and is_binary(coordinate) do
    with {:ok, parsed} <- parse(coordinate) do
      resolve_parsed(schema, parsed, coordinate)
    end
  end

  defp resolve_parsed(schema, {:type, type_name}, coordinate) do
    case lookup_type_by_name(schema, type_name) do
      nil -> {:error, "Type not found: #{coordinate}"}
      type -> {:ok, type}
    end
  end

  defp resolve_parsed(schema, {:field, type_name, field_name}, coordinate) do
    with {:ok, type} <- resolve_parsed(schema, {:type, type_name}, type_name),
         {:ok, field} <- get_field(type, field_name) do
      {:ok, field}
    else
      {:error, _} -> {:error, "Field not found: #{coordinate}"}
    end
  end

  defp resolve_parsed(schema, {:argument, type_name, field_name, arg_name}, coordinate) do
    with {:ok, field} <- resolve_parsed(schema, {:field, type_name, field_name}, "#{type_name}.#{field_name}"),
         {:ok, arg} <- get_argument(field, arg_name) do
      {:ok, arg}
    else
      {:error, _} -> {:error, "Argument not found: #{coordinate}"}
    end
  end

  defp resolve_parsed(schema, {:enum_value, enum_name, value_name}, coordinate) do
    with {:ok, enum_type} <- resolve_parsed(schema, {:type, enum_name}, enum_name),
         {:ok, value} <- get_enum_value(enum_type, value_name) do
      {:ok, value}
    else
      {:error, _} -> {:error, "Enum value not found: #{coordinate}"}
    end
  end

  defp resolve_parsed(schema, {:input_field, type_name, field_name}, coordinate) do
    with {:ok, input_type} <- resolve_parsed(schema, {:type, type_name}, type_name),
         {:ok, field} <- get_input_field(input_type, field_name) do
      {:ok, field}
    else
      {:error, _} -> {:error, "Input field not found: #{coordinate}"}
    end
  end

  defp resolve_parsed(schema, {:directive, directive_name}, coordinate) do
    case lookup_directive_by_name(schema, directive_name) do
      nil -> {:error, "Directive not found: #{coordinate}"}
      directive -> {:ok, directive}
    end
  end

  defp resolve_parsed(schema, {:directive_argument, directive_name, arg_name}, coordinate) do
    with {:ok, directive} <- resolve_parsed(schema, {:directive, directive_name}, "@#{directive_name}"),
         {:ok, arg} <- get_directive_argument(directive, arg_name) do
      {:ok, arg}
    else
      {:error, _} -> {:error, "Directive argument not found: #{coordinate}"}
    end
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp lookup_type_by_name(schema, name) do
    # Try to find type by external name
    schema.__absinthe_types__()
    |> Enum.find_value(fn {identifier, _} ->
      type = Absinthe.Schema.lookup_type(schema, identifier)

      if type && type.name == name do
        type
      end
    end)
  end

  defp lookup_directive_by_name(schema, name) do
    schema.__absinthe_directives__()
    |> Enum.find_value(fn {identifier, _} ->
      directive = Absinthe.Schema.lookup_directive(schema, identifier)

      if directive && (directive.name == name || Atom.to_string(directive.identifier) == name) do
        directive
      end
    end)
  end

  defp get_field(%{fields: fields}, field_name) when is_map(fields) do
    result =
      Enum.find_value(fields, fn {_, field} ->
        if field.name == field_name || Atom.to_string(field.identifier) == field_name do
          field
        end
      end)

    case result do
      nil -> {:error, :not_found}
      field -> {:ok, field}
    end
  end

  defp get_field(_, _), do: {:error, :not_found}

  defp get_argument(%{args: args}, arg_name) when is_map(args) do
    result =
      Enum.find_value(args, fn {_, arg} ->
        if arg.name == arg_name || Atom.to_string(arg.identifier) == arg_name do
          arg
        end
      end)

    case result do
      nil -> {:error, :not_found}
      arg -> {:ok, arg}
    end
  end

  defp get_argument(_, _), do: {:error, :not_found}

  defp get_enum_value(%Absinthe.Type.Enum{values: values}, value_name) when is_map(values) do
    result =
      Enum.find_value(values, fn {_, value} ->
        if value.name == value_name || Atom.to_string(value.value) == value_name do
          value
        end
      end)

    case result do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  defp get_enum_value(_, _), do: {:error, :not_found}

  defp get_input_field(%Absinthe.Type.InputObject{fields: fields}, field_name) when is_map(fields) do
    result =
      Enum.find_value(fields, fn {_, field} ->
        if field.name == field_name || Atom.to_string(field.identifier) == field_name do
          field
        end
      end)

    case result do
      nil -> {:error, :not_found}
      field -> {:ok, field}
    end
  end

  defp get_input_field(_, _), do: {:error, :not_found}

  defp get_directive_argument(%{args: args}, arg_name) when is_map(args) do
    result =
      Enum.find_value(args, fn {_, arg} ->
        if arg.name == arg_name || Atom.to_string(arg.identifier) == arg_name do
          arg
        end
      end)

    case result do
      nil -> {:error, :not_found}
      arg -> {:ok, arg}
    end
  end

  defp get_directive_argument(_, _), do: {:error, :not_found}
end
