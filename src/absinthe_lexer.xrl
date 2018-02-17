% Absinthe Lexer
%
% See the spec reference http://facebook.github.io/graphql/#sec-Appendix-Grammar-Summary
% The relevant version is also copied into this repo

Definitions.

% Ignored tokens
WhiteSpace          = [\x{0009}\x{000B}\x{000C}\x{0020}\x{00A0}]
_LineTerminator     = \x{000A}\x{000D}\x{2028}\x{2029}
LineTerminator      = [{_LineTerminator}]
Comment             = #[^{_LineTerminator}]*
Comma               = ,
Ignored             = {WhiteSpace}|{LineTerminator}|{Comment}|{Comma}

% Lexical tokens
Punctuator          = [!$():=@\[\]{|}]|\.\.\.
Name                = [_A-Za-z][_0-9A-Za-z]*

% Int Value
Digit               = [0-9]
NonZeroDigit        = [1-9]
NegativeSign        = -
IntegerPart         = {NegativeSign}?(0|{NonZeroDigit}{Digit}*)
IntValue            = {IntegerPart}

% Float Value
FractionalPart      = \.{Digit}+
Sign                = [+\-]
ExponentIndicator   = [eE]
ExponentPart        = {ExponentIndicator}{Sign}?{Digit}+
FloatValue          = {IntegerPart}{FractionalPart}|{IntegerPart}{ExponentPart}|{IntegerPart}{FractionalPart}{ExponentPart}

% Block String Value
EscapedBlockStringQuote = (\\""")
BlockStringCharacter    = (\n|\t|\r|[^\x{0000}-\x{001F}]|{EscapedBlockStringQuote})
BlockStringValue        = """{BlockStringCharacter}*"""

% String Value
HexDigit            = [0-9A-Fa-f]
EscapedUnicode      = u{HexDigit}{HexDigit}{HexDigit}{HexDigit}
EscapedCharacter    = ["\\\/bfnrt]
StringCharacter     = ([^\"{_LineTerminator}]|\\{EscapedUnicode}|\\{EscapedCharacter})
StringValue         = "{StringCharacter}*"

% Boolean Value
BooleanValue        = true|false

% Reserved words
ReservedWord        = query|mutation|subscription|fragment|on|implements|interface|union|scalar|enum|input|extend|type|directive|ON|null|schema

Rules.

{Ignored}           : skip_token.
{Punctuator}        : {token, {list_to_atom(TokenChars), TokenLine}}.
{ReservedWord}      : {token, {list_to_atom(TokenChars), TokenLine}}.
{IntValue}          : {token, {int_value, TokenLine, TokenChars}}.
{FloatValue}        : {token, {float_value, TokenLine, TokenChars}}.
{BlockStringValue}  : {token, {block_string_value, TokenLine, TokenChars}}.
{StringValue}       : {token, {string_value, TokenLine, TokenChars}}.
{BooleanValue}      : {token, {boolean_value, TokenLine, TokenChars}}.
{Name}              : {token, {name, TokenLine, TokenChars}}.

Erlang code.
