defmodule Absinthe.Lexer do
  import NimbleParsec

  # Codepoints
  @horizontal_tab 0x0009
  @newline 0x000A
  @carriage_return 0x000D
  @space 0x0020
  @unicode_final 0xFFFF
  @unicode_bom 0xFEFF

  # SourceCharacter :: /[\u0009\u000A\u000D\u0020-\uFFFF]/
  source_character =
    utf8_char([
      @horizontal_tab,
      @newline,
      @carriage_return,
      @space..@unicode_final
    ])

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
    |> repeat_while(source_character, {:not_line_terminator, []})

  # Comma :: ,
  comma = ascii_char([?,])

  # Ignored ::
  #   - UnicodeBOM
  #   - WhiteSpace
  #   - LineTerminator
  #   - Comment
  #   - Comma
  ignored =
    choice([
      unicode_bom,
      whitespace,
      line_terminator,
      comment,
      comma
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
    |> traverse({:atom_token, []})

  name_or_reserved_word =
    ascii_char([?_, ?A..?Z, ?a..?z])
    |> repeat(ascii_char([?_, ?0..?9, ?A..?Z, ?a..?z]))
    |> traverse({:name_or_reserved_word_token, []})

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
    |> traverse({:labeled_token, [:int_value]})

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
      integer_part |> traverse({:fill_mantissa, []}) |> concat(exponent_part),
      integer_part |> concat(fractional_part)
    ])
    |> traverse({:labeled_token, [:float_value]})

  # EscapedUnicode :: /[0-9A-Fa-f]{4}/
  escaped_unicode =
    times(ascii_char([?0..?9, ?A..?F, ?a..?f]), 4)
    |> traverse({:unescape_unicode, []})

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
      source_character
    ])

  # BlockStringCharacter ::
  #   - SourceCharacter but not `"""` or `\"""`
  #   - `\"""`

  # Note: Block string values are interpreted to exclude blank initial and trailing
  # lines and uniform indentation with {BlockStringValue()}.
  block_string_character =
    choice([
      string(~S(\""")) |> replace(~s(""")),
      source_character
    ])

  # StringValue ::
  #   - `"` StringCharacter* `"`
  #   - `"""` BlockStringCharacter* `"""`
  # TODO: Use block_string_character
  string_value =
    ascii_char([?"])
    |> repeat_while(string_character, {:not_end_of_quote, []})
    |> ascii_char([?"])
    |> traverse({:labeled_token, [:string_value]})

  block_string_value =
    ignore(string(~S(""")) |> traverse({:mark_block_string_start, []}))
    |> repeat_while(block_string_character, {:not_end_of_block_quote, []})
    |> ignore(string(~S(""")))
    |> traverse({:block_string_value_token, []})

  # BooleanValue : one of `true` `false`
  boolean_value =
    choice([
      string("true"),
      string("false")
    ])
    |> traverse({:boolean_value_token, []})

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

  def tokenize(input) do
    case do_tokenize(input) do
      {:ok, tokens, "", _, _, _} ->
        {:ok, tokens}

      {:ok, _, rest, _, {line, line_offset}, byte_offset} ->
        column = byte_offset - line_offset + 1
        {:error, rest, {line, column}}

      other ->
        other
    end
  end

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
        boolean_value,
        name_or_reserved_word
      ])
    )
  )

  defp fill_mantissa(_rest, raw, context, _, _), do: {'0.' ++ raw, context}

  defp unescape_unicode(_rest, content, context, _loc, _) do
    code = content |> Enum.reverse()
    value = :httpd_util.hexlist_to_integer(code)
    binary = :unicode.characters_to_binary([value])
    {[binary], context}
  end

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
    scalar
    schema
    subscription
    type
    union
  ) |> Enum.map(&String.to_charlist/1)

  defp name_or_reserved_word_token(rest, chars, context, loc, byte_offset) do
    value = chars |> Enum.reverse()
    do_name_or_reserved_word_token(rest, value, context, loc, byte_offset)
  end

  defp do_name_or_reserved_word_token(_rest, value, context, loc, byte_offset)
       when value in @reserved_words do
    token_name = value |> List.to_atom()
    {[{token_name, line_and_column(loc, byte_offset, length(value))}], context}
  end

  defp do_name_or_reserved_word_token(_rest, value, context, loc, byte_offset) do
    {[{:name, line_and_column(loc, byte_offset, length(value)), value}], context}
  end

  defp boolean_value_token(_rest, [token_string], context, loc, byte_offset) do
    value = token_string |> String.to_charlist()
    {[{:boolean_value, line_and_column(loc, byte_offset, length(value)), value}], context}
  end

  defp labeled_token(_rest, chars, context, loc, byte_offset, token_name) do
    value = chars |> Enum.reverse()
    {[{token_name, line_and_column(loc, byte_offset, length(value)), value}], context}
  end

  defp mark_block_string_start(_rest, chars, context, loc, byte_offset) do
    {[chars], Map.put(context, :token_location, line_and_column(loc, byte_offset, 3))}
  end

  defp block_string_value_token(_rest, chars, context, _loc, _byte_offset) do
    value = '"""' ++ (chars |> Enum.reverse()) ++ '"""'
    {[{:block_string_value, context.token_location, value}], Map.delete(context, :token_location)}
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
