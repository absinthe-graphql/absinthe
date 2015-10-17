-module(ex_graphql_parser).
-export([parse/1, parse_and_scan/1, format_error/1]).
-file("src/ex_graphql_parser.yrl", 206).

extract_atom({Value, _Line}) -> Value.
extract_token({_Token, _Line, Value}) -> list_to_binary(Value).
extract_quoted_string_token({_Token, _Line, Value}) -> list_to_binary(lists:sublist(Value, 2, length(Value) - 2)).
extract_integer({_Token, _Line, Value}) ->
  {Int, []} = string:to_integer(Value), Int.
extract_float({_Token, _Line, Value}) ->
  {Float, []} = string:to_float(Value), Float.
extract_boolean({_Token, _Line, "true"}) -> true;
extract_boolean({_Token, _Line, "false"}) -> false.
extract_keyword({Value, _Line}) -> list_to_binary(atom_to_list(Value)).
extract_line({_Token, Line}) -> Line;                                
extract_line({_Token, Line, _Value}) -> Line;
extract_line(_) -> nil.

extract_child_line([head|tail]) ->
    extract_child_line(head);
extract_child_line(#{loc := #{start := Line}}) ->
    Line;
extract_child_line(_) ->
    nil.

build_ast_node(Type, Node) ->
  build_ast_node(Type, Node, nil).
build_ast_node(Type, Node, #{start := nil}) ->
  build_ast_node(Type, Node, nil);
build_ast_node(Type, Node, Loc) ->
  Node#{'__struct__' => list_to_atom("Elixir.ExGraphQL.AST." ++ atom_to_list(Type)), loc => Loc}.

-file("/usr/local/lib/erlang/lib/parsetools-2.1/include/yeccpre.hrl", 0).
%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 1996-2015. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The parser generator will insert appropriate declarations before this line.%

-type yecc_ret() :: {'error', _} | {'ok', _}.

-spec parse(Tokens :: list()) -> yecc_ret().
parse(Tokens) ->
    yeccpars0(Tokens, {no_func, no_line}, 0, [], []).

-spec parse_and_scan({function() | {atom(), atom()}, [_]}
                     | {atom(), atom(), [_]}) -> yecc_ret().
parse_and_scan({F, A}) ->
    yeccpars0([], {{F, A}, no_line}, 0, [], []);
parse_and_scan({M, F, A}) ->
    Arity = length(A),
    yeccpars0([], {{fun M:F/Arity, A}, no_line}, 0, [], []).

-spec format_error(any()) -> [char() | list()].
format_error(Message) ->
    case io_lib:deep_char_list(Message) of
        true ->
            Message;
        _ ->
            io_lib:write(Message)
    end.

%% To be used in grammar files to throw an error message to the parser
%% toplevel. Doesn't have to be exported!
-compile({nowarn_unused_function, return_error/2}).
-spec return_error(integer(), any()) -> no_return().
return_error(Line, Message) ->
    throw({error, {Line, ?MODULE, Message}}).

-define(CODE_VERSION, "1.4").

yeccpars0(Tokens, Tzr, State, States, Vstack) ->
    try yeccpars1(Tokens, Tzr, State, States, Vstack)
    catch 
        error: Error ->
            Stacktrace = erlang:get_stacktrace(),
            try yecc_error_type(Error, Stacktrace) of
                Desc ->
                    erlang:raise(error, {yecc_bug, ?CODE_VERSION, Desc},
                                 Stacktrace)
            catch _:_ -> erlang:raise(error, Error, Stacktrace)
            end;
        %% Probably thrown from return_error/2:
        throw: {error, {_Line, ?MODULE, _M}} = Error ->
            Error
    end.

yecc_error_type(function_clause, [{?MODULE,F,ArityOrArgs,_} | _]) ->
    case atom_to_list(F) of
        "yeccgoto_" ++ SymbolL ->
            {ok,[{atom,_,Symbol}],_} = erl_scan:string(SymbolL),
            State = case ArityOrArgs of
                        [S,_,_,_,_,_,_] -> S;
                        _ -> state_is_unknown
                    end,
            {Symbol, State, missing_in_goto_table}
    end.

yeccpars1([Token | Tokens], Tzr, State, States, Vstack) ->
    yeccpars2(State, element(1, Token), States, Vstack, Token, Tokens, Tzr);
yeccpars1([], {{F, A},_Line}, State, States, Vstack) ->
    case apply(F, A) of
        {ok, Tokens, Endline} ->
            yeccpars1(Tokens, {{F, A}, Endline}, State, States, Vstack);
        {eof, Endline} ->
            yeccpars1([], {no_func, Endline}, State, States, Vstack);
        {error, Descriptor, _Endline} ->
            {error, Descriptor}
    end;
yeccpars1([], {no_func, no_line}, State, States, Vstack) ->
    Line = 999999,
    yeccpars2(State, '$end', States, Vstack, yecc_end(Line), [],
              {no_func, Line});
yeccpars1([], {no_func, Endline}, State, States, Vstack) ->
    yeccpars2(State, '$end', States, Vstack, yecc_end(Endline), [],
              {no_func, Endline}).

%% yeccpars1/7 is called from generated code.
%%
%% When using the {includefile, Includefile} option, make sure that
%% yeccpars1/7 can be found by parsing the file without following
%% include directives. yecc will otherwise assume that an old
%% yeccpre.hrl is included (one which defines yeccpars1/5).
yeccpars1(State1, State, States, Vstack, Token0, [Token | Tokens], Tzr) ->
    yeccpars2(State, element(1, Token), [State1 | States],
              [Token0 | Vstack], Token, Tokens, Tzr);
yeccpars1(State1, State, States, Vstack, Token0, [], {{_F,_A}, _Line}=Tzr) ->
    yeccpars1([], Tzr, State, [State1 | States], [Token0 | Vstack]);
yeccpars1(State1, State, States, Vstack, Token0, [], {no_func, no_line}) ->
    Line = yecctoken_end_location(Token0),
    yeccpars2(State, '$end', [State1 | States], [Token0 | Vstack],
              yecc_end(Line), [], {no_func, Line});
yeccpars1(State1, State, States, Vstack, Token0, [], {no_func, Line}) ->
    yeccpars2(State, '$end', [State1 | States], [Token0 | Vstack],
              yecc_end(Line), [], {no_func, Line}).

%% For internal use only.
yecc_end({Line,_Column}) ->
    {'$end', Line};
yecc_end(Line) ->
    {'$end', Line}.

yecctoken_end_location(Token) ->
    try erl_anno:end_location(element(2, Token)) of
        undefined -> yecctoken_location(Token);
        Loc -> Loc
    catch _:_ -> yecctoken_location(Token)
    end.

-compile({nowarn_unused_function, yeccerror/1}).
yeccerror(Token) ->
    Text = yecctoken_to_string(Token),
    Location = yecctoken_location(Token),
    {error, {Location, ?MODULE, ["syntax error before: ", Text]}}.

-compile({nowarn_unused_function, yecctoken_to_string/1}).
yecctoken_to_string(Token) ->
    try erl_scan:text(Token) of
        undefined -> yecctoken2string(Token);
        Txt -> Txt
    catch _:_ -> yecctoken2string(Token)
    end.

yecctoken_location(Token) ->
    try erl_scan:location(Token)
    catch _:_ -> element(2, Token)
    end.

-compile({nowarn_unused_function, yecctoken2string/1}).
yecctoken2string({atom, _, A}) -> io_lib:write(A);
yecctoken2string({integer,_,N}) -> io_lib:write(N);
yecctoken2string({float,_,F}) -> io_lib:write(F);
yecctoken2string({char,_,C}) -> io_lib:write_char(C);
yecctoken2string({var,_,V}) -> io_lib:format("~s", [V]);
yecctoken2string({string,_,S}) -> io_lib:write_string(S);
yecctoken2string({reserved_symbol, _, A}) -> io_lib:write(A);
yecctoken2string({_Cat, _, Val}) -> io_lib:format("~p",[Val]);
yecctoken2string({dot, _}) -> "'.'";
yecctoken2string({'$end', _}) ->
    [];
yecctoken2string({Other, _}) when is_atom(Other) ->
    io_lib:write(Other);
yecctoken2string(Other) ->
    io_lib:write(Other).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



-file("src/ex_graphql_parser.erl", 207).

-dialyzer({nowarn_function, yeccpars2/7}).
yeccpars2(0=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(1=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_1(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(2=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_2(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(3=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_3(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(4=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(5=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_5(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(6=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(7=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_7(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(8=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_8(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(9=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_9(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(10=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_10(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(11=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_11(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(12=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_12(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(13=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(14=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(15=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_15(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(16=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(17=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(18=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(19=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(20=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(21=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(22=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(23=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(24=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(25=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(26=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_26(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(27=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_27(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(28=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_28(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(29=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_29(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(30=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_30(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(31=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_31(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(32=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_32(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(33=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_33(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(34=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(35=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(36=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(37=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_37(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(38=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_38(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(39=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_39(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(40=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_40(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(41=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_41(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(42=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_42(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(43=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_43(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(44=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_44(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(45=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_45(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(46=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_46(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(47=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_47(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(48=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_48(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(49=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_49(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(50=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_50(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(51=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_51(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(52=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(53=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_53(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(54=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_54(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(55=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(56=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_56(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(57=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_57(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(58=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_58(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(59=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(60=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_60(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(61=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_61(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(62=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(63=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_63(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(64=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_64(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(65=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_65(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(66=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(67=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(68=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(69=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_69(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(70=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_70(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(71=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_71(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(72=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_72(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(73=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(74=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_74(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(75=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(76=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(77=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_77(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(78=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_78(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(79=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_79(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(80=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_80(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(81=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_81(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(82=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_82(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(83=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_83(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(84=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_84(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(85=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_85(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(86=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(87=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_87(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(88=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_88(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(89=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(90=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_90(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(91=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_91(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(92=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(93=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_93(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(94=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(95=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_95(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(96=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_96(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(97=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_97(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(98=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_98(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(99=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_99(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(100=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_100(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(101=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_101(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(102=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(103=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_103(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(104=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_104(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(105=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_105(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(106=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_106(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(107=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_107(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(108=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_108(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(109=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_109(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(110=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_110(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(111=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_111(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(112=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_112(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(113=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_113(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(114=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_114(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(115=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_115(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(116=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(117=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_117(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(118=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(119=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_119(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(120=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_120(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(121=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(122=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_122(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(123=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_123(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(124=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_124(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(125=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(126=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(127=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_127(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(128=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_128(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(129=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_129(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(130=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_130(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(131=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(132=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(133=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(134=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(135=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_135(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(136=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_136(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(137=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_137(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(138=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_138(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(139=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(140=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_140(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(141=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_141(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(142=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(143=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_143(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(144=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_144(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(145=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_145(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(146=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_146(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(147=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_147(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(148=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_148(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(149=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(150=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_150(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(151=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_151(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(152=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(153=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_153(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(154=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(155=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_155(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(156=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_156(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(157=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_157(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(158=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_158(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(159=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(160=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_160(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(161=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(162=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_162(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(163=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_163(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(164=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(165=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_165(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(166=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(167=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_167(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(168=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(169=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_169(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(170=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_170(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(171=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_171(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(172=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(173=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_53(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(174=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_174(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(175=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_57(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(176=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_176(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(177=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_177(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(178=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_178(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(179=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(180=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_180(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(181=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_181(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(182=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_182(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(183=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_183(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(184=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(185=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_185(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(186=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_186(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(187=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_53(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(188=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_188(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(189=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_57(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(190=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(191=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_191(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(192=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_192(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(193=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_193(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(194=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(195=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_195(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(196=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_196(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(197=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_197(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(198=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_198(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(199=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_199(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(200=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_200(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(201=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_57(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(202=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_202(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(Other, _, _, _, _, _, _) ->
 erlang:error({yecc_bug,"1.4",{missing_state_in_action_table, Other}}).

-dialyzer({nowarn_function, yeccpars2_0/7}).
yeccpars2_0(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_1(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Definition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_4_(Stack),
 'yeccgoto_\'OperationDefinition\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_5(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_6(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Definition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_11(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Definition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_13/7}).
yeccpars2_13(_S, '$end', _Ss, Stack, _T, _Ts, _Tzr) ->
 {ok, hd(Stack)};
yeccpars2_13(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_14_(Stack),
 'yeccgoto_\'Document\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_15(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_15_(Stack),
 'yeccgoto_\'Definitions\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_16: see yeccpars2_6

-dialyzer({nowarn_function, yeccpars2_17/7}).
yeccpars2_17(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_17(_, _, _, _, T, _, _) ->
 yeccerror(T).

-dialyzer({nowarn_function, yeccpars2_18/7}).
yeccpars2_18(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_19: see yeccpars2_6

%% yeccpars2_20: see yeccpars2_6

yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_21_(Stack),
 'yeccgoto_\'OperationType\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_22_(Stack),
 'yeccgoto_\'OperationType\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_23: see yeccpars2_6

%% yeccpars2_24: see yeccpars2_6

%% yeccpars2_25: see yeccpars2_6

yeccpars2_26(S, '...', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_26(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_26(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_27/7}).
yeccpars2_27(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_28(S, '...', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_28_(Stack),
 'yeccgoto_\'Selections\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_30(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_30(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 110, Ss, Stack, T, Ts, Tzr);
yeccpars2_30(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_30(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_30_(Stack),
 'yeccgoto_\'Field\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Selection\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Selection\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_33(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Selection\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_34: see yeccpars2_6

yeccpars2_35(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_35(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_36_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_37(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_37_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_38(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_38_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_39(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_39_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_40(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_40_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_41(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_41_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_42(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_42_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_43(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_43_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_44(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_44_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_45(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_45_(Stack),
 'yeccgoto_\'Name\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_46(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_46_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_47(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_47_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_48(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_48_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_49(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_49_(Stack),
 'yeccgoto_\'NameWithoutOn\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_50(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'FragmentName\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_51(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_51(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_51_(Stack),
 'yeccgoto_\'FragmentSpread\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_52: see yeccpars2_6

-dialyzer({nowarn_function, yeccpars2_53/7}).
yeccpars2_53(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_53(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_53(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_54(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'TypeCondition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_55_(Stack),
 'yeccgoto_\'NamedType\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_56(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_56_(Stack),
 'yeccgoto_\'InlineFragment\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_57/7}).
yeccpars2_57(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_57(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_58(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_58_(Stack),
 'yeccgoto_\'Directives\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_59: see yeccpars2_6

yeccpars2_60(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_60(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_60_(Stack),
 'yeccgoto_\'Directive\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_61(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_61_(Stack),
 'yeccgoto_\'Directive\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_62: see yeccpars2_6

-dialyzer({nowarn_function, yeccpars2_63/7}).
yeccpars2_63(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_63(_, _, _, _, T, _, _) ->
 yeccerror(T).

-dialyzer({nowarn_function, yeccpars2_64/7}).
yeccpars2_64(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_64(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_65(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_65_(Stack),
 'yeccgoto_\'ArgumentList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_66_(Stack),
 'yeccgoto_\'ArgumentList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_67_(Stack),
 'yeccgoto_\'Arguments\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_68(S, '$', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, boolean_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, float_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, int_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, string_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_70_(Stack),
 'yeccgoto_\'Argument\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_71_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'EnumValue\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_73_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_74_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_75: see yeccpars2_6

yeccpars2_76(S, '$', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(S, ']', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(S, boolean_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(S, float_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(S, int_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(S, string_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_77(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_77_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_78(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_78_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_79(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_79_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_80(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_80_(Stack),
 'yeccgoto_\'Value\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_81(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_82/7}).
yeccpars2_82(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_82(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_83(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_83_(Stack),
 'yeccgoto_\'ObjectFields\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_84/7}).
yeccpars2_84(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_84(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_85_(Stack),
 'yeccgoto_\'ObjectValue\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_86: see yeccpars2_68

yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_87_(Stack),
 'yeccgoto_\'ObjectField\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_88_(Stack),
 'yeccgoto_\'ObjectFields\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_89_(Stack),
 'yeccgoto_\'ObjectValue\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_90/7}).
yeccpars2_90(S, ']', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_90(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_91(S, '$', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, boolean_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, float_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, int_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, string_value, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_91_(Stack),
 'yeccgoto_\'Values\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_92(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_92_(Stack),
 'yeccgoto_\'ListValue\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_93(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_93_(Stack),
 'yeccgoto_\'Values\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_94_(Stack),
 'yeccgoto_\'ListValue\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_95_(Stack),
 'yeccgoto_\'Variable\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_96(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_96_(Stack),
 'yeccgoto_\'Directives\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_97_(Stack),
 'yeccgoto_\'InlineFragment\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_98_(Stack),
 'yeccgoto_\'FragmentSpread\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_99(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_99(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_99(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_99_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_100(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_100_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_101(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_101_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_102(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_102(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_102(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_102_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_103(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_103_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_104(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_104_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_105(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_105_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_106(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_106_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_107(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_107_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_108(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_108(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_108_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_109(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_109_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_110(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_110_(Stack),
 'yeccgoto_\'Alias\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_111(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_111_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_112(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_112_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_113_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_114_(Stack),
 'yeccgoto_\'Field\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_115_(Stack),
 'yeccgoto_\'Selections\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_116_(Stack),
 'yeccgoto_\'SelectionSet\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_117/7}).
yeccpars2_117(S, '=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 118, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_118: see yeccpars2_6

yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_119_(Stack),
 'yeccgoto_\'UnionTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_120(S, '|', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 121, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_120_(Stack),
 'yeccgoto_\'UnionMembers\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_121: see yeccpars2_6

yeccpars2_122(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_122_(Stack),
 'yeccgoto_\'UnionMembers\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_123/7}).
yeccpars2_123(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 125, Ss, Stack, T, Ts, Tzr);
yeccpars2_123(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 126, Ss, Stack, T, Ts, Tzr);
yeccpars2_123(_, _, _, _, T, _, _) ->
 yeccerror(T).

-dialyzer({nowarn_function, yeccpars2_124/7}).
yeccpars2_124(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 159, Ss, Stack, T, Ts, Tzr);
yeccpars2_124(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_125: see yeccpars2_6

%% yeccpars2_126: see yeccpars2_6

-dialyzer({nowarn_function, yeccpars2_127/7}).
yeccpars2_127(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 133, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 134, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(_, _, _, _, T, _, _) ->
 yeccerror(T).

-dialyzer({nowarn_function, yeccpars2_128/7}).
yeccpars2_128(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 131, Ss, Stack, T, Ts, Tzr);
yeccpars2_128(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_129(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_129_(Stack),
 'yeccgoto_\'FieldDefinitionList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_130(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_130_(Stack),
 'yeccgoto_\'FieldDefinitionList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_131_(Stack),
 'yeccgoto_\'ObjectTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_132/7}).
yeccpars2_132(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 154, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_133: see yeccpars2_6

yeccpars2_134(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 139, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_135_(Stack),
 'yeccgoto_\'FieldDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Type\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_137(S, '!', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 143, Ss, Stack, T, Ts, Tzr);
yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Type\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_138(S, '!', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 142, Ss, Stack, T, Ts, Tzr);
yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Type\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_139: see yeccpars2_134

-dialyzer({nowarn_function, yeccpars2_140/7}).
yeccpars2_140(S, ']', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_140(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_141(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_141_(Stack),
 'yeccgoto_\'ListType\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_142(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_142_(Stack),
 'yeccgoto_\'NonNullType\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_143(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_143_(Stack),
 'yeccgoto_\'NonNullType\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_144/7}).
yeccpars2_144(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 149, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(_, _, _, _, T, _, _) ->
 yeccerror(T).

-dialyzer({nowarn_function, yeccpars2_145/7}).
yeccpars2_145(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 148, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_146(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_146_(Stack),
 'yeccgoto_\'InputValueDefinitionList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_147(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_147_(Stack),
 'yeccgoto_\'InputValueDefinitionList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_148(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_148_(Stack),
 'yeccgoto_\'ArgumentsDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_149: see yeccpars2_134

yeccpars2_150(S, '=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 152, Ss, Stack, T, Ts, Tzr);
yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_150_(Stack),
 'yeccgoto_\'InputValueDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_151_(Stack),
 'yeccgoto_\'InputValueDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_152: see yeccpars2_68

yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_153_(Stack),
 'yeccgoto_\'DefaultValue\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_154: see yeccpars2_134

yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_155_(Stack),
 'yeccgoto_\'FieldDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_156_(Stack),
 'yeccgoto_\'ImplementsInterfaces\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_157(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_157_(Stack),
 'yeccgoto_\'NamedTypeList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_158_(Stack),
 'yeccgoto_\'NamedTypeList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_159: see yeccpars2_6

-dialyzer({nowarn_function, yeccpars2_160/7}).
yeccpars2_160(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 161, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_161(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_161_(Stack),
 'yeccgoto_\'ObjectTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_162(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_162_(Stack),
 'yeccgoto_\'ScalarTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_163/7}).
yeccpars2_163(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 164, Ss, Stack, T, Ts, Tzr);
yeccpars2_163(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_164: see yeccpars2_6

-dialyzer({nowarn_function, yeccpars2_165/7}).
yeccpars2_165(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 166, Ss, Stack, T, Ts, Tzr);
yeccpars2_165(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_166(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_166_(Stack),
 'yeccgoto_\'InterfaceTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_167/7}).
yeccpars2_167(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 168, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_168: see yeccpars2_6

-dialyzer({nowarn_function, yeccpars2_169/7}).
yeccpars2_169(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_169(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_170(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_170_(Stack),
 'yeccgoto_\'InputObjectTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_171/7}).
yeccpars2_171(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 172, Ss, Stack, T, Ts, Tzr);
yeccpars2_171(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_172: see yeccpars2_6

%% yeccpars2_173: see yeccpars2_53

yeccpars2_174(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_174_(Stack),
 'yeccgoto_\'FragmentDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_175: see yeccpars2_57

yeccpars2_176(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_176_(Stack),
 'yeccgoto_\'FragmentDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_177(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_177_(Stack),
 'yeccgoto_\'TypeExtensionDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_178/7}).
yeccpars2_178(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 179, Ss, Stack, T, Ts, Tzr);
yeccpars2_178(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_179: see yeccpars2_6

-dialyzer({nowarn_function, yeccpars2_180/7}).
yeccpars2_180(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 184, Ss, Stack, T, Ts, Tzr);
yeccpars2_180(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_181(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, extend, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, fragment, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, implements, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, input, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, mutation, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, null, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, on, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, query, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, scalar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_181_(Stack),
 'yeccgoto_\'EnumValueDefinitionList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_182(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'EnumValueDefinition\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_183(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_183_(Stack),
 'yeccgoto_\'EnumValueDefinitionList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_184_(Stack),
 'yeccgoto_\'EnumTypeDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_185_(Stack),
 'yeccgoto_\'Definitions\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_186/7}).
yeccpars2_186(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 190, Ss, Stack, T, Ts, Tzr);
yeccpars2_186(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_186(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_186(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_187: see yeccpars2_53

yeccpars2_188(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_188_(Stack),
 'yeccgoto_\'OperationDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_189: see yeccpars2_57

-dialyzer({nowarn_function, yeccpars2_190/7}).
yeccpars2_190(S, '$', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_190(_, _, _, _, T, _, _) ->
 yeccerror(T).

-dialyzer({nowarn_function, yeccpars2_191/7}).
yeccpars2_191(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 198, Ss, Stack, T, Ts, Tzr);
yeccpars2_191(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_192(S, '$', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_192(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_192_(Stack),
 'yeccgoto_\'VariableDefinitionList\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

-dialyzer({nowarn_function, yeccpars2_193/7}).
yeccpars2_193(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 194, Ss, Stack, T, Ts, Tzr);
yeccpars2_193(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_194: see yeccpars2_134

yeccpars2_195(S, '=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 152, Ss, Stack, T, Ts, Tzr);
yeccpars2_195(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_195_(Stack),
 'yeccgoto_\'VariableDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_196(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_196_(Stack),
 'yeccgoto_\'VariableDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_197_(Stack),
 'yeccgoto_\'VariableDefinitionList\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_198(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_198_(Stack),
 'yeccgoto_\'VariableDefinitions\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_199_(Stack),
 'yeccgoto_\'OperationDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_200_(Stack),
 'yeccgoto_\'OperationDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_201: see yeccpars2_57

yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_202_(Stack),
 'yeccgoto_\'OperationDefinition\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

'yeccgoto_\'Alias\''(26, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(34, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Alias\''(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(34, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Argument\''(62, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_65(65, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Argument\''(65, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_65(65, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ArgumentList\''(62, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_64(64, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ArgumentList\''(65=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Arguments\''(30, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_109(109, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Arguments\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_61(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Arguments\''(99, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(102, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ArgumentsDefinition\''(127, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(132, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'DefaultValue\''(150=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'DefaultValue\''(195=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_196(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Definition\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_15(15, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Definition\''(15, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_15(15, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Definitions\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Definitions\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Directive\''(30, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(51, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(58, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(99, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(109, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(173, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(186, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directive\''(187, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Directives\''(30, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_108(108, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(51=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(57, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(58=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_96(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(99, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_101(101, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_104(104, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(109, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_112(112, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(173, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(175, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(186, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(189, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Directives\''(187, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(201, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Document\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(13, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'EnumTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'EnumValue\''(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(91=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(179=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_182(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValue\''(181=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_182(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'EnumValueDefinition\''(179, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_181(181, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValueDefinition\''(181, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_181(181, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'EnumValueDefinitionList\''(179, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_180(180, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EnumValueDefinitionList\''(181=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_183(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Field\''(26=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_33(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Field\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_33(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FieldDefinition\''(126, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(129, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinition\''(129, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(129, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinition\''(159, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(129, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinition\''(164, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(129, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FieldDefinitionList\''(126, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_128(128, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinitionList\''(129=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinitionList\''(159, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_160(160, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FieldDefinitionList\''(164, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(165, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FragmentDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FragmentDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FragmentName\''(18, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_171(171, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FragmentName\''(35, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_51(51, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FragmentSpread\''(26=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FragmentSpread\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ImplementsInterfaces\''(123, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(124, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'InlineFragment\''(26=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InlineFragment\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'InputObjectTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InputObjectTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'InputValueDefinition\''(133, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(146, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InputValueDefinition\''(146, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(146, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InputValueDefinition\''(168, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(146, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'InputValueDefinitionList\''(133, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_145(145, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InputValueDefinitionList\''(146=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_147(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InputValueDefinitionList\''(168, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_169(169, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'InterfaceTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'InterfaceTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ListType\''(134, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(138, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListType\''(139, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(138, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListType\''(149, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(138, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListType\''(154, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(138, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListType\''(194, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(138, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ListValue\''(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListValue\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListValue\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListValue\''(91=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ListValue\''(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Name\''(6, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(186, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(16, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(178, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(19, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_167(167, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(20, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_163(163, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_162(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(24, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(123, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(25, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(26, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(30, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(30, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(34, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(99, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(52=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(59, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_60(60, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(62, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_63(63, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(65, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_63(63, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(75=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_84(84, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(83, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_84(84, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(91=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(121=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(125=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(126, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(129, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(133, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_144(144, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(134=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(139=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(146, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_144(144, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(149=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(154=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(157=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(159, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(164, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(168, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_144(144, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(172=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(179=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(181=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Name\''(194=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'NameWithoutOn\''(6=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(16=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(18=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_50(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(20=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(26=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(34=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(35=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_50(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(52=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(59=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(62=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(65=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(75=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(83=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(91=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(121=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(125=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(126=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(129=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(134=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(139=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(146=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(149=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(154=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(157=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(159=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(164=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(172=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(179=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(181=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameWithoutOn\''(194=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'NamedType\''(52=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_54(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(118, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_120(120, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(121, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_120(120, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(125, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_157(157, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(134, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(137, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(139, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(137, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(149, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(137, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(154, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(137, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(157, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_157(157, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(172=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_54(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedType\''(194, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(137, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'NamedTypeList\''(125=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NamedTypeList\''(157=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'NonNullType\''(134=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NonNullType\''(139=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NonNullType\''(149=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NonNullType\''(154=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NonNullType\''(194=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ObjectField\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(83, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectField\''(83, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(83, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ObjectFields\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(82, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectFields\''(83=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ObjectTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectTypeDefinition\''(17=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_177(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ObjectValue\''(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectValue\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectValue\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectValue\''(91=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ObjectValue\''(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'OperationDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OperationDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'OperationType\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(6, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OperationType\''(15, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(6, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'ScalarTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ScalarTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Selection\''(26, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_28(28, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Selection\''(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_28(28, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'SelectionSet\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(30=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_107(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(57=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(99=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_100(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(101=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_106(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_103(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(104=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_105(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(108=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_111(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(173=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_174(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(175=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_176(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(186=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_188(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(187=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(189=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'SelectionSet\''(201=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Selections\''(26, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_27(27, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Selections\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Type\''(134=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Type\''(139, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_140(140, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Type\''(149, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_150(150, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Type\''(154=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Type\''(194, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_195(195, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'TypeCondition\''(52, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(53, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'TypeCondition\''(172, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(173, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'TypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'TypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'TypeExtensionDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'TypeExtensionDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'UnionMembers\''(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionMembers\''(121=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'UnionTypeDefinition\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionTypeDefinition\''(15=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Value\''(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Value\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(91, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Value\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Value\''(91, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(91, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Value\''(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Values\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(90, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Values\''(91=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_93(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Variable\''(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(91=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(190, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_193(193, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Variable\''(192, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_193(193, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'VariableDefinition\''(190, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(192, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'VariableDefinition\''(192, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(192, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'VariableDefinitionList\''(190, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(191, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'VariableDefinitionList\''(192=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'VariableDefinitions\''(186, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(187, Cat, Ss, Stack, T, Ts, Tzr).

-compile({inline,yeccpars2_4_/1}).
-file("src/ex_graphql_parser.yrl", 33).
yeccpars2_4_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'OperationDefinition' , # { operation => query , selectionSet => __1 } , # { start => extract_child_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_14_/1}).
-file("src/ex_graphql_parser.yrl", 21).
yeccpars2_14_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Document' , # { definitions => __1 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_15_/1}).
-file("src/ex_graphql_parser.yrl", 23).
yeccpars2_15_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_21_/1}).
-file("src/ex_graphql_parser.yrl", 31).
yeccpars2_21_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_atom ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_22_/1}).
-file("src/ex_graphql_parser.yrl", 30).
yeccpars2_22_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_atom ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_28_/1}).
-file("src/ex_graphql_parser.yrl", 63).
yeccpars2_28_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_30_/1}).
-file("src/ex_graphql_parser.yrl", 78).
yeccpars2_30_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { name => __1 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_36_/1}).
-file("src/ex_graphql_parser.yrl", 116).
yeccpars2_36_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_37_/1}).
-file("src/ex_graphql_parser.yrl", 118).
yeccpars2_37_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_38_/1}).
-file("src/ex_graphql_parser.yrl", 110).
yeccpars2_38_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_39_/1}).
-file("src/ex_graphql_parser.yrl", 112).
yeccpars2_39_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_40_/1}).
-file("src/ex_graphql_parser.yrl", 117).
yeccpars2_40_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_41_/1}).
-file("src/ex_graphql_parser.yrl", 113).
yeccpars2_41_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_42_/1}).
-file("src/ex_graphql_parser.yrl", 109).
yeccpars2_42_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_43_/1}).
-file("src/ex_graphql_parser.yrl", 107).
yeccpars2_43_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_token ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_44_/1}).
-file("src/ex_graphql_parser.yrl", 119).
yeccpars2_44_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_45_/1}).
-file("src/ex_graphql_parser.yrl", 122).
yeccpars2_45_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_46_/1}).
-file("src/ex_graphql_parser.yrl", 108).
yeccpars2_46_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_47_/1}).
-file("src/ex_graphql_parser.yrl", 115).
yeccpars2_47_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_48_/1}).
-file("src/ex_graphql_parser.yrl", 111).
yeccpars2_48_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_49_/1}).
-file("src/ex_graphql_parser.yrl", 114).
yeccpars2_49_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   extract_keyword ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_51_/1}).
-file("src/ex_graphql_parser.yrl", 70).
yeccpars2_51_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FragmentSpread' , # { name => __2 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_55_/1}).
-file("src/ex_graphql_parser.yrl", 56).
yeccpars2_55_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'NamedType' , # { name => __1 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_56_/1}).
-file("src/ex_graphql_parser.yrl", 73).
yeccpars2_56_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InlineFragment' , # { typeCondition => __3 , selectionSet => __4 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_58_/1}).
-file("src/ex_graphql_parser.yrl", 102).
yeccpars2_58_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_60_/1}).
-file("src/ex_graphql_parser.yrl", 104).
yeccpars2_60_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Directive' , # { name => __2 } )
  end | __Stack].

-compile({inline,yeccpars2_61_/1}).
-file("src/ex_graphql_parser.yrl", 105).
yeccpars2_61_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Directive' , # { name => __2 , arguments => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_65_/1}).
-file("src/ex_graphql_parser.yrl", 98).
yeccpars2_65_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_66_/1}).
-file("src/ex_graphql_parser.yrl", 99).
yeccpars2_66_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_67_/1}).
-file("src/ex_graphql_parser.yrl", 97).
yeccpars2_67_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_70_/1}).
-file("src/ex_graphql_parser.yrl", 100).
yeccpars2_70_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Argument' , # { name => __1 , value => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_71_/1}).
-file("src/ex_graphql_parser.yrl", 131).
yeccpars2_71_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ObjectValue' , # { fields => __1 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_73_/1}).
-file("src/ex_graphql_parser.yrl", 130).
yeccpars2_73_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ListValue' , # { values => __1 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_74_/1}).
-file("src/ex_graphql_parser.yrl", 129).
yeccpars2_74_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'EnumValue' , # { value => __1 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_77_/1}).
-file("src/ex_graphql_parser.yrl", 128).
yeccpars2_77_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'BooleanValue' , # { value => extract_boolean ( __1 ) } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_78_/1}).
-file("src/ex_graphql_parser.yrl", 126).
yeccpars2_78_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FloatValue' , # { value => extract_float ( __1 ) } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_79_/1}).
-file("src/ex_graphql_parser.yrl", 125).
yeccpars2_79_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'IntValue' , # { value => extract_integer ( __1 ) } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_80_/1}).
-file("src/ex_graphql_parser.yrl", 127).
yeccpars2_80_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'StringValue' , # { value => extract_quoted_string_token ( __1 ) } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_83_/1}).
-file("src/ex_graphql_parser.yrl", 142).
yeccpars2_83_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_85_/1}).
-file("src/ex_graphql_parser.yrl", 140).
yeccpars2_85_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_87_/1}).
-file("src/ex_graphql_parser.yrl", 144).
yeccpars2_87_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ObjectField' , # { name => __1 , value => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_88_/1}).
-file("src/ex_graphql_parser.yrl", 143).
yeccpars2_88_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_89_/1}).
-file("src/ex_graphql_parser.yrl", 141).
yeccpars2_89_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_91_/1}).
-file("src/ex_graphql_parser.yrl", 137).
yeccpars2_91_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_92_/1}).
-file("src/ex_graphql_parser.yrl", 135).
yeccpars2_92_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_93_/1}).
-file("src/ex_graphql_parser.yrl", 138).
yeccpars2_93_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_94_/1}).
-file("src/ex_graphql_parser.yrl", 136).
yeccpars2_94_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_95_/1}).
-file("src/ex_graphql_parser.yrl", 49).
yeccpars2_95_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Variable' , # { name => __2 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_96_/1}).
-file("src/ex_graphql_parser.yrl", 103).
yeccpars2_96_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_97_/1}).
-file("src/ex_graphql_parser.yrl", 74).
yeccpars2_97_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InlineFragment' , # { typeCondition => __3 , directives => __4 , selectionSet => __5 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_98_/1}).
-file("src/ex_graphql_parser.yrl", 71).
yeccpars2_98_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FragmentSpread' , # { name => __2 , directives => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_99_/1}).
-file("src/ex_graphql_parser.yrl", 86).
yeccpars2_99_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { alias => __1 , name => __2 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_100_/1}).
-file("src/ex_graphql_parser.yrl", 88).
yeccpars2_100_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { alias => __1 , name => __2 , selectionSet => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_101_/1}).
-file("src/ex_graphql_parser.yrl", 90).
yeccpars2_101_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { alias => __1 , name => __2 , directives => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_102_/1}).
-file("src/ex_graphql_parser.yrl", 87).
yeccpars2_102_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { alias => __1 , name => __2 , arguments => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_103_/1}).
-file("src/ex_graphql_parser.yrl", 89).
yeccpars2_103_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { alias => __1 , name => __2 , arguments => __3 , selectionSet => __4 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_104_/1}).
-file("src/ex_graphql_parser.yrl", 91).
yeccpars2_104_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { alias => __1 , name => __2 , arguments => __3 , directives => __4 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_105_/1}).
-file("src/ex_graphql_parser.yrl", 93).
yeccpars2_105_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { alias => __1 , name => __2 , arguments => __3 , directives => __4 , selectionSet => __5 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_106_/1}).
-file("src/ex_graphql_parser.yrl", 92).
yeccpars2_106_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { alias => __1 , name => __2 , directives => __3 , selectionSet => __4 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_107_/1}).
-file("src/ex_graphql_parser.yrl", 81).
yeccpars2_107_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { name => __1 , selectionSet => __2 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_108_/1}).
-file("src/ex_graphql_parser.yrl", 80).
yeccpars2_108_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { name => __1 , directives => __2 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_109_/1}).
-file("src/ex_graphql_parser.yrl", 79).
yeccpars2_109_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { name => __1 , arguments => __2 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_110_/1}).
-file("src/ex_graphql_parser.yrl", 95).
yeccpars2_110_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_111_/1}).
-file("src/ex_graphql_parser.yrl", 83).
yeccpars2_111_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { name => __1 , arguments => __2 , selectionSet => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_112_/1}).
-file("src/ex_graphql_parser.yrl", 84).
yeccpars2_112_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { name => __1 , arguments => __2 , directives => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_113_/1}).
-file("src/ex_graphql_parser.yrl", 85).
yeccpars2_113_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { name => __1 , arguments => __2 , directives => __3 , selectionSet => __4 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_114_/1}).
-file("src/ex_graphql_parser.yrl", 82).
yeccpars2_114_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'Field' , # { name => __1 , directives => __2 , selectionSet => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_115_/1}).
-file("src/ex_graphql_parser.yrl", 64).
yeccpars2_115_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_116_/1}).
-file("src/ex_graphql_parser.yrl", 61).
yeccpars2_116_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'SelectionSet' , # { selections => __2 } , # { start => extract_line ( __1 ) , 'end' => extract_line ( __3 ) } )
  end | __Stack].

-compile({inline,yeccpars2_119_/1}).
-file("src/ex_graphql_parser.yrl", 181).
yeccpars2_119_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'UnionTypeDefinition' , # { name => __2 , types => __4 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_120_/1}).
-file("src/ex_graphql_parser.yrl", 183).
yeccpars2_120_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_122_/1}).
-file("src/ex_graphql_parser.yrl", 184).
yeccpars2_122_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_129_/1}).
-file("src/ex_graphql_parser.yrl", 164).
yeccpars2_129_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_130_/1}).
-file("src/ex_graphql_parser.yrl", 165).
yeccpars2_130_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_131_/1}).
-file("src/ex_graphql_parser.yrl", 155).
yeccpars2_131_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ObjectTypeDefinition' , # { name => __2 , fields => __4 } , # { start => extract_line ( __1 ) , 'end' => extract_line ( __5 ) } )
  end | __Stack].

-compile({inline,yeccpars2_135_/1}).
-file("src/ex_graphql_parser.yrl", 166).
yeccpars2_135_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FieldDefinition' , # { name => __1 , type => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_141_/1}).
-file("src/ex_graphql_parser.yrl", 57).
yeccpars2_141_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ListType' , # { type => __2 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_142_/1}).
-file("src/ex_graphql_parser.yrl", 59).
yeccpars2_142_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'NonNullType' , # { type => __1 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_143_/1}).
-file("src/ex_graphql_parser.yrl", 58).
yeccpars2_143_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'NonNullType' , # { type => __1 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_146_/1}).
-file("src/ex_graphql_parser.yrl", 171).
yeccpars2_146_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_147_/1}).
-file("src/ex_graphql_parser.yrl", 172).
yeccpars2_147_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_148_/1}).
-file("src/ex_graphql_parser.yrl", 169).
yeccpars2_148_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_150_/1}).
-file("src/ex_graphql_parser.yrl", 174).
yeccpars2_150_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InputValueDefinition' , # { name => __1 , type => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_151_/1}).
-file("src/ex_graphql_parser.yrl", 175).
yeccpars2_151_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InputValueDefinition' , # { name => __1 , type => __3 , defaultValue => __4 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_153_/1}).
-file("src/ex_graphql_parser.yrl", 51).
yeccpars2_153_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_155_/1}).
-file("src/ex_graphql_parser.yrl", 167).
yeccpars2_155_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FieldDefinition' , # { name => __1 , arguments => __2 , type => __4 } )
  end | __Stack].

-compile({inline,yeccpars2_156_/1}).
-file("src/ex_graphql_parser.yrl", 159).
yeccpars2_156_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_157_/1}).
-file("src/ex_graphql_parser.yrl", 161).
yeccpars2_157_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_158_/1}).
-file("src/ex_graphql_parser.yrl", 162).
yeccpars2_158_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_161_/1}).
-file("src/ex_graphql_parser.yrl", 157).
yeccpars2_161_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ObjectTypeDefinition' , # { name => __2 , interfaces => __3 , fields => __5 } , # { start => extract_line ( __1 ) , 'end' => extract_line ( __6 ) } )
  end | __Stack].

-compile({inline,yeccpars2_162_/1}).
-file("src/ex_graphql_parser.yrl", 186).
yeccpars2_162_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'ScalarTypeDefinition' , # { name => __2 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_166_/1}).
-file("src/ex_graphql_parser.yrl", 178).
yeccpars2_166_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InterfaceTypeDefinition' , # { name => __2 , fields => __4 } , # { start => extract_line ( __1 ) , 'end' => extract_line ( __5 ) } )
  end | __Stack].

-compile({inline,yeccpars2_170_/1}).
-file("src/ex_graphql_parser.yrl", 197).
yeccpars2_170_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'InputObjectTypeDefinition' , # { name => __2 , fields => __4 } , # { start => extract_line ( __1 ) , 'end' => extract_line ( __5 ) } )
  end | __Stack].

-compile({inline,yeccpars2_174_/1}).
-file("src/ex_graphql_parser.yrl", 39).
yeccpars2_174_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FragmentDefinition' , # { name => __2 , typeCondition => __4 , selectionSet => __5 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_176_/1}).
-file("src/ex_graphql_parser.yrl", 40).
yeccpars2_176_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'FragmentDefinition' , # { name => __2 , typeCondition => __4 , directives => __5 , selectionSet => __6 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_177_/1}).
-file("src/ex_graphql_parser.yrl", 200).
yeccpars2_177_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'TypeExtensionDefinition' , # { definition => __2 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_181_/1}).
-file("src/ex_graphql_parser.yrl", 191).
yeccpars2_181_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_183_/1}).
-file("src/ex_graphql_parser.yrl", 192).
yeccpars2_183_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_184_/1}).
-file("src/ex_graphql_parser.yrl", 189).
yeccpars2_184_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'EnumTypeDefinition' , # { name => __2 , values => __4 } , # { start => extract_line ( __1 ) , 'end' => extract_line ( __5 ) } )
  end | __Stack].

-compile({inline,yeccpars2_185_/1}).
-file("src/ex_graphql_parser.yrl", 24).
yeccpars2_185_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_188_/1}).
-file("src/ex_graphql_parser.yrl", 34).
yeccpars2_188_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'OperationDefinition' , # { operation => __1 , name => __2 , selectionSet => __3 } , # { start => extract_line ( __2 ) } )
  end | __Stack].

-compile({inline,yeccpars2_192_/1}).
-file("src/ex_graphql_parser.yrl", 45).
yeccpars2_192_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_195_/1}).
-file("src/ex_graphql_parser.yrl", 47).
yeccpars2_195_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'VariableDefinition' , # { variable => __1 , type => __3 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_196_/1}).
-file("src/ex_graphql_parser.yrl", 48).
yeccpars2_196_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'VariableDefinition' , # { variable => __1 , type => __3 , defaultValue => __4 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_197_/1}).
-file("src/ex_graphql_parser.yrl", 46).
yeccpars2_197_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_198_/1}).
-file("src/ex_graphql_parser.yrl", 44).
yeccpars2_198_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_199_/1}).
-file("src/ex_graphql_parser.yrl", 36).
yeccpars2_199_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'OperationDefinition' , # { operation => __1 , name => __2 , directives => __3 , selectionSet => __4 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_200_/1}).
-file("src/ex_graphql_parser.yrl", 35).
yeccpars2_200_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'OperationDefinition' , # { operation => __1 , name => __2 , variableDefinitions => __3 , selectionSet => __4 } , # { start => extract_line ( __1 ) } )
  end | __Stack].

-compile({inline,yeccpars2_202_/1}).
-file("src/ex_graphql_parser.yrl", 37).
yeccpars2_202_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   build_ast_node ( 'OperationDefinition' , # { operation => __1 , name => __2 , variableDefinitions => __3 , directives => __4 , selectionSet => __5 } , # { start => extract_line ( __1 ) } )
  end | __Stack].


-file("src/ex_graphql_parser.yrl", 235).
