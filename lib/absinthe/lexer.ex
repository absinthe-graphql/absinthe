defmodule Absinthe.Lexer do
  import NimbleParsec

  # Codepoints
  @horizontal_tab 0x0009
  @newline 0x000A
  @carriage_return 0x000D
  @space 0x0020
  @unicode_bom 0xFEFF

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

  # EscapedUnicode :: /[0-9A-Fa-f]{4}/
  escaped_unicode =
    times(ascii_char([?0..?9, ?A..?F, ?a..?f]), 4)
    |> post_traverse({:unescape_unicode, []})

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
  #   - \u EscapedUnicode
  #   - \ EscapedCharacter
  string_character =
    choice([
      ignore(string(~S(\u))) |> concat(escaped_unicode),
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

  @spec tokenize(binary()) :: {:ok, [any()]} | {:error, binary(), {integer(), non_neg_integer()}}
  def tokenize(input) do
    lines = String.split(input, ~r/\r?\n/)

    case do_tokenize(input) do
      {:ok, tokens, "", _, _, _} ->
        # Enum.map(tokens, &convert_token_column(&1, lines))
        tokens = optimized_map_token_column(tokens, lines)
        token_count = length(tokens)
        NewRelic.add_attributes(absinthe_token_count: token_count)
        NewRelic.report_custom_metric("Absinthe/Lexer/TokenCount", token_count)
        {:ok, tokens}

      {:ok, _, rest, _, {line, line_offset}, byte_offset} ->
        byte_column = byte_offset - line_offset + 1
        {:error, rest, byte_loc_to_char_loc({line, byte_column}, lines)}
    end
  end

  defp optimized_map_token_column(tokens, [first_line | remaining_lines]) do
    # RIP me. Lines and columns returned by the tokenizer are 1-indexed.
    # The lists and strings we are processing are 0-indexed.
    # This means we'll have to start the line number and character/byte offsets at 1,
    # but we'll have to adjust the math later when dealing with lists and strings.
    do_optimized_map_token_column(
      [],
      tokens,
      1,
      first_line,
      remaining_lines,
      1,
      1
    )
  end

  # le base case! if there are no tokens left, return the accumulated results
  defp do_optimized_map_token_column(results, [] = _tokens, _, _, _, _, _), do: results

  # le recursive case
  defp do_optimized_map_token_column(
         # Accumulator. Tokens with locations adjusted from bytes to chars. Ex: [{:foo, {1, 2}}, {:bar, {2, 1}}]
         results,
         # The raw tokens (will take one off the front of the list at each step)
         [current_token | rest_tokens],
         # Which line number we're currently working on
         line_num,
         # The line string that we're currently working on
         line_part,
         # The list of lines that come after the current line (remove them as we process)
         remaining_lines,
         # For the current line, how many characters we've counted so far.
         char_offset,
         # For the current line, how many bytes we've counted so far
         byte_offset
       ) do
    # extract byte loc (gotta handle two token formats)
    {token_line_num, token_byte_col} =
      case current_token do
        {_, byte_location, _} -> byte_location
        {_, byte_location} -> byte_location
      end

    # update the current line cursor if we need to move to the next line
    {current_line_num, current_line, remaining_lines, char_offset, byte_offset} =
      cond do
        token_line_num > line_num ->
          adjust_lines_cursor(remaining_lines, token_line_num, line_num)

        token_line_num == line_num ->
          {line_num, line_part, remaining_lines, char_offset, byte_offset}
      end

    # count the characters leading up to current token's column, and add the previous offset
    adjusted_byte_col = token_byte_col - byte_offset
    partial_byte_prefix = binary_part(current_line, 0, adjusted_byte_col)
    char_col = String.length(partial_byte_prefix) + char_offset

    # prepare data for the next recursive call:
    # cut that token off the front of the line string (removing what we've already processed)
    next_line_part =
      binary_part(current_line, adjusted_byte_col, byte_size(current_line) - adjusted_byte_col)

    # get the next offsets ready
    next_byte_offset = token_byte_col
    next_char_offset = char_col

    # gotta handle two token formats
    result =
      case current_token do
        {ident, _, data} -> {ident, {token_line_num, char_col}, data}
        {ident, _} -> {ident, {token_line_num, char_col}}
      end

    results = results ++ [result]

    do_optimized_map_token_column(
      results,
      rest_tokens,
      current_line_num,
      next_line_part,
      remaining_lines,
      next_char_offset,
      next_byte_offset
    )
  end

  defp adjust_lines_cursor(lines, desired_line_num, current_line_num) do
    {_discarded, next_lines} = Enum.split(lines, desired_line_num - current_line_num - 1)
    [current_line | remaining_lines] = next_lines
    {desired_line_num, current_line, remaining_lines, 1, 1}
  end

  defp byte_loc_to_char_loc({line, byte_col}, lines) do
    current_line = Enum.at(lines, line - 1)
    byte_prefix = binary_part(current_line, 0, byte_col)
    char_col = String.length(byte_prefix)
    {line, char_col}
  end

  @spec do_tokenize(binary()) ::
          {:ok, [any()], binary(), map(), {pos_integer(), pos_integer()}, pos_integer()}
  defparsec(
    :do_tokenize,
    repeat(
      choice([
        ignore(ignored),
        comment,
        punctuator,
        block_string_value,
        string_value,
        float_value,
        int_value,
        boolean_value_or_name_or_reserved_word
      ])
    )
  )

  defp fill_mantissa(_rest, raw, context, _, _), do: {'0.' ++ raw, context}

  defp unescape_unicode(_rest, content, context, _loc, _) do
    code = content |> Enum.reverse()
    value = :erlang.list_to_integer(code, 16)
    binary = :unicode.characters_to_binary([value])
    {[binary], context}
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

  defp boolean_value_or_name_or_reserved_word(rest, chars, context, loc, byte_offset) do
    value = chars |> Enum.reverse()
    do_boolean_value_or_name_or_reserved_word(rest, value, context, loc, byte_offset)
  end

  defp do_boolean_value_or_name_or_reserved_word(_rest, value, context, loc, byte_offset)
       when value in @boolean_words do
    {[{:boolean_value, line_and_column(loc, byte_offset, length(value)), value}], context}
  end

  defp do_boolean_value_or_name_or_reserved_word(_rest, value, context, loc, byte_offset)
       when value in @reserved_words do
    token_name = value |> List.to_atom()
    {[{token_name, line_and_column(loc, byte_offset, length(value))}], context}
  end

  defp do_boolean_value_or_name_or_reserved_word(_rest, value, context, loc, byte_offset) do
    {[{:name, line_and_column(loc, byte_offset, length(value)), value}], context}
  end

  defp labeled_token(_rest, chars, context, loc, byte_offset, token_name) do
    value = chars |> Enum.reverse()
    {[{token_name, line_and_column(loc, byte_offset, length(value)), value}], context}
  end

  defp mark_string_start(_rest, chars, context, loc, byte_offset) do
    {[chars], Map.put(context, :token_location, line_and_column(loc, byte_offset, 1))}
  end

  defp mark_block_string_start(_rest, _chars, context, loc, byte_offset) do
    {[], Map.put(context, :token_location, line_and_column(loc, byte_offset, 3))}
  end

  defp block_string_value_token(_rest, chars, context, _loc, _byte_offset) do
    value = '"""' ++ (chars |> Enum.reverse()) ++ '"""'
    {[{:block_string_value, context.token_location, value}], Map.delete(context, :token_location)}
  end

  defp string_value_token(_rest, chars, context, _loc, _byte_offset) do
    value = '"' ++ tl(chars |> Enum.reverse()) ++ '"'
    {[{:string_value, context.token_location, value}], Map.delete(context, :token_location)}
  end

  defp atom_token(_rest, chars, context, loc, byte_offset) do
    value = chars |> Enum.reverse()
    token_atom = value |> List.to_atom()
    {[{token_atom, line_and_column(loc, byte_offset, length(value))}], context}
  end

  def line_and_column({line, line_offset}, byte_offset, column_correction) do
    column = byte_offset - line_offset - column_correction + 1
    {line, column}
  end

  defp not_line_terminator(<<?\n, _::binary>>, context, _, _), do: {:halt, context}
  defp not_line_terminator(<<?\r, _::binary>>, context, _, _), do: {:halt, context}
  defp not_line_terminator(_, context, _, _), do: {:cont, context}
end
