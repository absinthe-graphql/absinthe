defmodule Absinthe.Lexer do
  import NimbleParsec

  # Codepoints
  @horizontal_tab 0x0009
  @newline 0x000A
  @carriage_return 0x000D
  @space 0x0020
  @unicode_bom 0xFEFF

  @stopped_at_token_limit ":stopped_at_token_limit"

  # SourceCharacter :: /[\u0009\u000A\u000D\u0020-\uFFFF]/

  any_unicode = utf8_char([])

  # ## Ignored Tokens

  # UnicodeBOM :: "Byte Order Mark (U+FEFF)"
  unicode_bom = utf8_char([@unicode_bom])

  # WhiteSpace ::
  #   - "Horizontal Tab (U+0009)"
  #   - "Space (U+0020)"
  whitespace =
    ascii_char([
      @horizontal_tab,
      @space
    ])

  # LineTerminator ::
  #   - "New Line (U+000A)"
  #   - "Carriage Return (U+000D)" [ lookahead ! "New Line (U+000A)" ]
  #   - "Carriage Return (U+000D)" "New Line (U+000A)"
  line_terminator =
    choice([
      ascii_char([@newline]),
      ascii_char([@carriage_return])
      |> optional(ascii_char([@newline]))
    ])

  # Comment :: `#` CommentChar*
  # CommentChar :: SourceCharacter but not LineTerminator
  comment =
    string("#")
    |> repeat_while(any_unicode, {:not_line_terminator, []})

  # Comma :: ,
  comma = ascii_char([?,])

  # Ampersand :: &
  ampersand = ascii_char([?&])

  # Ignored ::
  #   - UnicodeBOM
  #   - WhiteSpace
  #   - LineTerminator
  #   - Comment
  #   - Comma
  #   - Ampersand
  ignored =
    choice([
      unicode_bom,
      whitespace,
      line_terminator,
      comment,
      comma,
      ampersand
    ])

  # ## Lexical Tokens

  #   - Punctuator
  #   - Name
  #   - IntValue
  #   - FloatValue
  #   - StringValue

  punctuator =
    choice([
      ascii_char([
        ?!,
        ?$,
        ?(,
        ?),
        ?:,
        ?=,
        ?@,
        ?[,
        ?],
        ?{,
        ?|,
        ?}
      ]),
      times(ascii_char([?.]), 3)
    ])
    |> post_traverse({:atom_token, []})

  boolean_value_or_name_or_reserved_word =
    ascii_char([?_, ?A..?Z, ?a..?z])
    |> repeat(ascii_char([?_, ?0..?9, ?A..?Z, ?a..?z]))
    |> post_traverse({:boolean_value_or_name_or_reserved_word, []})

  # NegativeSign :: -
  negative_sign = ascii_char([?-])

  # Digit :: one of 0 1 2 3 4 5 6 7 8 9
  digit = ascii_char([?0..?9])

  # NonZeroDigit :: Digit but not `0`
  non_zero_digit = ascii_char([?1..?9])

  # IntegerPart ::
  #   - NegativeSign? 0
  #   - NegativeSign? NonZeroDigit Digit*
  integer_part =
    optional(negative_sign)
    |> choice([
      ascii_char([?0]),
      non_zero_digit |> repeat(digit)
    ])

  # IntValue :: IntegerPart
  int_value =
    empty()
    |> concat(integer_part)
    |> post_traverse({:labeled_token, [:int_value]})

  # FractionalPart :: . Digit+
  fractional_part =
    ascii_char([?.])
    |> times(digit, min: 1)

  # ExponentIndicator :: one of `e` `E`
  exponent_indicator = ascii_char([?e, ?E])

  # Sign :: one of + -
  sign = ascii_char([?+, ?-])

  # ExponentPart :: ExponentIndicator Sign? Digit+
  exponent_part =
    exponent_indicator
    |> optional(sign)
    |> times(digit, min: 1)

  # FloatValue ::
  #   - IntegerPart FractionalPart
  #   - IntegerPart ExponentPart
  #   - IntegerPart FractionalPart ExponentPart
  float_value =
    choice([
      integer_part |> concat(fractional_part) |> concat(exponent_part),
      integer_part |> post_traverse({:fill_mantissa, []}) |> concat(exponent_part),
      integer_part |> concat(fractional_part)
    ])
    |> post_traverse({:labeled_token, [:float_value]})

  # EscapedUnicode (Fixed-width) :: /[0-9A-Fa-f]{4}/
  # Per GraphQL September 2025 spec, this supports BMP characters and surrogate pairs
  escaped_unicode_fixed =
    times(ascii_char([?0..?9, ?A..?F, ?a..?f]), 4)
    |> post_traverse({:unescape_unicode_fixed, []})

  # EscapedUnicode (Variable-width) :: \u{ [0-9A-Fa-f]+ }
  # Per GraphQL September 2025 spec, supports full Unicode range U+0000 to U+10FFFF
  escaped_unicode_variable =
    ignore(ascii_char([?{]))
    |> times(ascii_char([?0..?9, ?A..?F, ?a..?f]), min: 1)
    |> ignore(ascii_char([?}]))
    |> post_traverse({:unescape_unicode_variable, []})

  # EscapedCharacter :: one of `"` \ `/` b f n r t
  escaped_character =
    choice([
      ascii_char([?"]),
      ascii_char([?\\]),
      ascii_char([?/]),
      ascii_char([?b]) |> replace(?\b),
      ascii_char([?f]) |> replace(?\f),
      ascii_char([?n]) |> replace(?\n),
      ascii_char([?r]) |> replace(?\r),
      ascii_char([?t]) |> replace(?\t)
    ])

  # StringCharacter ::
  #   - SourceCharacter but not `"` or \ or LineTerminator
  #   - \u{ EscapedUnicode } (variable-width, September 2025 spec)
  #   - \u EscapedUnicode (fixed-width, legacy)
  #   - \ EscapedCharacter
  string_character =
    choice([
      # Variable-width Unicode escape: \u{XXXXXX}
      ignore(string(~S(\u))) |> concat(escaped_unicode_variable),
      # Fixed-width Unicode escape: \uXXXX (with surrogate pair support)
      ignore(string(~S(\u))) |> concat(escaped_unicode_fixed),
      ignore(ascii_char([?\\])) |> concat(escaped_character),
      any_unicode
    ])

  # BlockStringCharacter ::
  #   - SourceCharacter but not `"""` or `\"""`
  #   - `\"""`

  # Note: Block string values are interpreted to exclude blank initial and trailing
  # lines and uniform indentation with {BlockStringValue()}.
  block_string_character =
    choice([
      ignore(ascii_char([?\\])) |> concat(times(ascii_char([?"]), 3)),
      any_unicode
    ])

  # StringValue ::
  #   - `"` StringCharacter* `"`
  #   - `"""` BlockStringCharacter* `"""`
  string_value =
    ignore(ascii_char([?"]))
    |> post_traverse({:mark_string_start, []})
    |> repeat_while(string_character, {:not_end_of_quote, []})
    |> ignore(ascii_char([?"]))
    |> post_traverse({:string_value_token, []})

  block_string_value =
    ignore(string(~S(""")))
    |> post_traverse({:mark_block_string_start, []})
    |> repeat_while(block_string_character, {:not_end_of_block_quote, []})
    |> ignore(string(~S(""")))
    |> post_traverse({:block_string_value_token, []})

  defp not_end_of_quote(<<?", _::binary>>, context, _, _) do
    {:halt, context}
  end

  defp not_end_of_quote(rest, context, current_line, current_offset) do
    not_line_terminator(rest, context, current_line, current_offset)
  end

  defp not_end_of_block_quote(<<?", ?", ?", _::binary>>, context, _, _) do
    {:halt, context}
  end

  defp not_end_of_block_quote(_, context, _, _) do
    {:cont, context}
  end

  @spec tokenize(binary(), Keyword.t()) ::
          {:ok, [any()]}
          | {:error, binary(), {integer(), non_neg_integer()}}
          | {:error, :exceeded_token_limit}
          | {:error, :invalid_unicode_escape, binary(), {integer(), non_neg_integer()}}
  def tokenize(input, options \\ []) do
    lines = String.split(input, ~r/\r?\n/)

    tokenize_opts = [context: %{token_limit: Keyword.get(options, :token_limit, :infinity)}]

    case do_tokenize(input, tokenize_opts) do
      {:error, @stopped_at_token_limit, _, _, _, _} ->
        {:error, :exceeded_token_limit}

      # Handle Unicode escape validation errors
      {:error, message, _rest, _context, {line, line_offset}, byte_offset}
      when is_binary(message) ->
        byte_column = byte_offset - line_offset + 1
        {:error, :invalid_unicode_escape, message, byte_loc_to_char_loc({line, byte_column}, lines)}

      {:ok, tokens, "", _, _, _} ->
        tokens = convert_token_columns_from_byte_to_char(tokens, lines)
        {:ok, tokens}

      {:ok, _, rest, _, {line, line_offset}, byte_offset} ->
        byte_column = byte_offset - line_offset + 1
        {:error, rest, byte_loc_to_char_loc({line, byte_column}, lines)}
    end
  end

  defp convert_token_columns_from_byte_to_char(tokens, [first_line | next_lines]) do
    initial_cursor_state = %{
      line_num_cursor: 1,
      current_line_substring: first_line,
      current_line_char_offset: 1,
      current_line_byte_offset: 1,
      next_lines: next_lines
    }

    Enum.map_reduce(tokens, initial_cursor_state, fn current_token, cursor_state ->
      {token_line_num, token_byte_col} =
        case current_token do
          {_, {token_line_num, token_byte_col}, _} -> {token_line_num, token_byte_col}
          {_, {token_line_num, token_byte_col}} -> {token_line_num, token_byte_col}
        end

      cursor_state = maybe_move_cursor_to_next_line(cursor_state, token_line_num)

      adjusted_byte_col = token_byte_col - cursor_state.current_line_byte_offset

      line_part_from_prev_to_current_token =
        binary_part(cursor_state.current_line_substring, 0, adjusted_byte_col)

      token_char_col =
        String.length(line_part_from_prev_to_current_token) +
          cursor_state.current_line_char_offset

      updated_line_substring =
        binary_part(
          cursor_state.current_line_substring,
          adjusted_byte_col,
          byte_size(cursor_state.current_line_substring) - adjusted_byte_col
        )

      next_cursor_state =
        cursor_state
        |> Map.put(:current_line_substring, updated_line_substring)
        |> Map.put(:current_line_byte_offset, token_byte_col)
        |> Map.put(:current_line_char_offset, token_char_col)

      result =
        case current_token do
          {ident, _, data} -> {ident, {token_line_num, token_char_col}, data}
          {ident, _} -> {ident, {token_line_num, token_char_col}}
        end

      {result, next_cursor_state}
    end)
    |> case do
      {results, _} -> results
    end
  end

  defp maybe_move_cursor_to_next_line(
         %{line_num_cursor: line_num_cursor} = cursor_state,
         token_line_num
       )
       when line_num_cursor == token_line_num,
       do: cursor_state

  defp maybe_move_cursor_to_next_line(
         %{line_num_cursor: line_num_cursor} = cursor_state,
         token_line_num
       )
       when line_num_cursor < token_line_num,
       do: move_cursor_to_next_line(cursor_state, token_line_num)

  defp move_cursor_to_next_line(
         %{line_num_cursor: line_num_cursor, next_lines: next_lines} = _cursor_state,
         token_line_num
       ) do
    {_completed, unprocessed_lines} = Enum.split(next_lines, token_line_num - line_num_cursor - 1)

    [current_line | next_lines] = unprocessed_lines

    %{
      line_num_cursor: token_line_num,
      current_line_substring: current_line,
      current_line_char_offset: 1,
      current_line_byte_offset: 1,
      next_lines: next_lines
    }
  end

  defp byte_loc_to_char_loc({line, byte_col}, lines) do
    current_line = Enum.at(lines, line - 1)
    byte_prefix = binary_part(current_line, 0, byte_col)
    char_col = String.length(byte_prefix)
    {line, char_col}
  end

  @spec do_tokenize(binary()) ::
          {:ok, [any()], binary(), map(), {pos_integer(), pos_integer()}, pos_integer()}
          | {:error, String.t(), String.t(), map(), {non_neg_integer(), non_neg_integer()},
             non_neg_integer()}
  defparsec(
    :do_tokenize,
    repeat(
      choice([
        ignore(ignored),
        punctuator,
        block_string_value,
        string_value,
        float_value,
        int_value,
        boolean_value_or_name_or_reserved_word
      ])
    )
  )

  defp fill_mantissa(rest, raw, context, _, _), do: {rest, ~c"0." ++ raw, context}

  # Unicode scalar value validation per GraphQL September 2025 spec:
  # Valid ranges: U+0000 to U+D7FF, U+E000 to U+10FFFF
  # Invalid: surrogate code points U+D800 to U+DFFF (except as surrogate pairs in fixed-width)
  defp is_unicode_scalar_value?(value) when value >= 0x0000 and value <= 0xD7FF, do: true
  defp is_unicode_scalar_value?(value) when value >= 0xE000 and value <= 0x10FFFF, do: true
  defp is_unicode_scalar_value?(_), do: false

  # Check if value is a high surrogate (U+D800 to U+DBFF)
  defp is_high_surrogate?(value), do: value >= 0xD800 and value <= 0xDBFF

  # Check if value is a low surrogate (U+DC00 to U+DFFF)
  defp is_low_surrogate?(value), do: value >= 0xDC00 and value <= 0xDFFF

  # Decode a surrogate pair to a Unicode scalar value
  defp decode_surrogate_pair(high, low) do
    0x10000 + ((high - 0xD800) * 0x400) + (low - 0xDC00)
  end

  # Variable-width Unicode escape: \u{XXXXXX}
  # Must be a valid Unicode scalar value (not a surrogate)
  defp unescape_unicode_variable(rest, content, context, _loc, _) do
    code = content |> Enum.reverse()
    value = :erlang.list_to_integer(code, 16)

    if is_unicode_scalar_value?(value) do
      binary = :unicode.characters_to_binary([value])
      {rest, [binary], context}
    else
      {:error, "Invalid Unicode scalar value in escape sequence"}
    end
  end

  # Fixed-width Unicode escape: \uXXXX
  # Handles BMP characters and surrogate pairs for supplementary characters
  defp unescape_unicode_fixed(rest, content, context, _loc, _) do
    code = content |> Enum.reverse()
    value = :erlang.list_to_integer(code, 16)

    cond do
      # Valid BMP character (not a surrogate)
      is_unicode_scalar_value?(value) ->
        binary = :unicode.characters_to_binary([value])
        {rest, [binary], context}

      # High surrogate - check for following low surrogate to form a pair
      is_high_surrogate?(value) ->
        case rest do
          # Look ahead for \uXXXX pattern
          <<?\\, ?u, h1, h2, h3, h4, remaining::binary>>
          when h1 in ~c"0123456789ABCDEFabcdef" and
                 h2 in ~c"0123456789ABCDEFabcdef" and
                 h3 in ~c"0123456789ABCDEFabcdef" and
                 h4 in ~c"0123456789ABCDEFabcdef" ->
            low_code = [h1, h2, h3, h4]
            low_value = :erlang.list_to_integer(low_code, 16)

            if is_low_surrogate?(low_value) do
              # Valid surrogate pair - decode to scalar value
              scalar = decode_surrogate_pair(value, low_value)
              binary = :unicode.characters_to_binary([scalar])
              {remaining, [binary], context}
            else
              # High surrogate not followed by low surrogate
              {:error, "Invalid Unicode escape: high surrogate not followed by low surrogate"}
            end

          _ ->
            # High surrogate without following escape sequence
            {:error, "Invalid Unicode escape: lone high surrogate"}
        end

      # Lone low surrogate (invalid)
      is_low_surrogate?(value) ->
        {:error, "Invalid Unicode escape: lone low surrogate"}

      # Out of range
      true ->
        {:error, "Invalid Unicode scalar value in escape sequence"}
    end
  end

  @boolean_words ~w(
    true
    false
  ) |> Enum.map(&String.to_charlist/1)

  @reserved_words ~w(
    directive
    enum
    extend
    fragment
    implements
    input
    interface
    mutation
    null
    on
    ON
    query
    repeatable
    scalar
    schema
    subscription
    type
    union
  ) |> Enum.map(&String.to_charlist/1)

  defp boolean_value_or_name_or_reserved_word(
         _,
         _,
         %{token_count: count, token_limit: limit} = _context,
         _,
         _
       )
       when count >= limit do
    {:error, @stopped_at_token_limit}
  end

  defp boolean_value_or_name_or_reserved_word(rest, chars, context, loc, byte_offset) do
    context = Map.update(context, :token_count, 1, &(&1 + 1))
    value = chars |> Enum.reverse()
    do_boolean_value_or_name_or_reserved_word(rest, value, context, loc, byte_offset)
  end

  defp do_boolean_value_or_name_or_reserved_word(rest, value, context, loc, byte_offset)
       when value in @boolean_words do
    {rest, [{:boolean_value, line_and_column(loc, byte_offset, length(value)), value}], context}
  end

  defp do_boolean_value_or_name_or_reserved_word(rest, value, context, loc, byte_offset)
       when value in @reserved_words do
    token_name = value |> List.to_atom()
    {rest, [{token_name, line_and_column(loc, byte_offset, length(value))}], context}
  end

  defp do_boolean_value_or_name_or_reserved_word(rest, value, context, loc, byte_offset) do
    {rest, [{:name, line_and_column(loc, byte_offset, length(value)), value}], context}
  end

  defp labeled_token(_, _, %{token_count: count, token_limit: limit} = _context, _, _, _)
       when count >= limit,
       do: {:error, @stopped_at_token_limit}

  defp labeled_token(rest, chars, context, loc, byte_offset, token_name) do
    context = Map.update(context, :token_count, 1, &(&1 + 1))
    value = chars |> Enum.reverse()
    {rest, [{token_name, line_and_column(loc, byte_offset, length(value)), value}], context}
  end

  defp mark_string_start(rest, chars, context, loc, byte_offset) do
    {rest, [chars], Map.put(context, :token_location, line_and_column(loc, byte_offset, 1))}
  end

  defp mark_block_string_start(rest, _chars, context, loc, byte_offset) do
    {rest, [], Map.put(context, :token_location, line_and_column(loc, byte_offset, 3))}
  end

  defp block_string_value_token(_, _, %{token_count: count, token_limit: limit} = _context, _, _)
       when count >= limit,
       do: {:error, @stopped_at_token_limit}

  defp block_string_value_token(rest, chars, context, _loc, _byte_offset) do
    context = Map.update(context, :token_count, 1, &(&1 + 1))
    value = ~c"\"\"\"" ++ (chars |> Enum.reverse()) ++ ~c"\"\"\""

    {rest, [{:block_string_value, context.token_location, value}],
     Map.delete(context, :token_location)}
  end

  defp string_value_token(_, _, %{token_count: count, token_limit: limit} = _context, _, _)
       when count >= limit,
       do: {:error, @stopped_at_token_limit}

  defp string_value_token(rest, chars, context, _loc, _byte_offset) do
    context = Map.update(context, :token_count, 1, &(&1 + 1))
    value = ~c"\"" ++ tl(chars |> Enum.reverse()) ++ ~c"\""
    {rest, [{:string_value, context.token_location, value}], Map.delete(context, :token_location)}
  end

  defp atom_token(_, _, %{token_count: count, token_limit: limit} = _context, _, _)
       when count >= limit do
    {:error, @stopped_at_token_limit}
  end

  defp atom_token(rest, chars, context, loc, byte_offset) do
    context = Map.update(context, :token_count, 1, &(&1 + 1))
    value = chars |> Enum.reverse()
    token_atom = value |> List.to_atom()

    {rest, [{token_atom, line_and_column(loc, byte_offset, length(value))}], context}
  end

  def line_and_column({line, line_offset}, byte_offset, column_correction) do
    column = byte_offset - line_offset - column_correction + 1
    {line, column}
  end

  defp not_line_terminator(<<?\n, _::binary>>, context, _, _), do: {:halt, context}
  defp not_line_terminator(<<?\r, _::binary>>, context, _, _), do: {:halt, context}
  defp not_line_terminator(_, context, _, _), do: {:cont, context}
end
