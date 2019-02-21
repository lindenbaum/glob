%%%=============================================================================
%%%
%%%               |  o __   _|  _  __  |_   _       _ _   (TM)
%%%               |_ | | | (_| (/_ | | |_) (_| |_| | | |
%%%
%%% @copyright (C) 2015, Lindenbaum GmbH
%%%
%%% Permission to use, copy, modify, and/or distribute this software for any
%%% purpose with or without fee is hereby granted, provided that the above
%%% copyright notice and this permission notice appear in all copies.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%%% ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%%% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
%%%
%%% @doc
%%% A library application to work with `glob' patterns.
%%%
%%% This implementation provides the same `glob' pattern facilities as `bash'.
%%% Syntax (partly from [https://en.wikipedia.org/wiki/Glob_%28programming%29)]:
%%%   `?': Match exactly one unknown character.
%%%   `*': Match any number of unknown characters from the position in which it
%%%        appears to the end of the subject also match any number of unknown
%%%        characters (regardless of the position where it appears, including at
%%%        the start and/or multiple times.
%%%   `[characters]': Match a character as part of a group of characters.
%%%   `[!characters]': Match any character but the ones specified.
%%%   `[character-charcter]': Match a character as part of a character range.
%%%   `[!character-charcter]': Match any character but the range specified.
%%%
%%% The underlying implementation utilizes the `re' module which means that a
%%% given `glob' pattern will be converted into a regular expression. For
%%% convenience this module features an API that is quite similar to the `re'
%%% module. Although, the shorthand {@link matches/1} enables a more intuitive
%%% and simple experience.
%%%
%%% As `glob' relies on `re' it offers support for `unicode' input. However,
%%% this support comes with the same restrictions known from `re'.
%%% @end
%%%=============================================================================

-module(glob).

%% API
-export([compile/1, compile/2, run/2, matches/2]).

-opaque mp() :: {?MODULE, tuple()}. %% in fact tuple() referes to an re:mp()
-export_type([mp/0]).

-define(COMPILE_OPTS, [{newline, anycrlf}, dotall, dollar_endonly]).

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc
%% Pre-compiles a `glob' expression/pattern. Same as `compile(Expr, false)'.
%% @end
%%------------------------------------------------------------------------------
-spec compile(iodata()) -> {ok, mp()} | {error, term()}.
compile(Expr) -> compile(Expr, false).

%%------------------------------------------------------------------------------
%% @doc
%% Pre-compiles a `glob' expression/pattern. Pre-compiling an expression/pattern
%% improves performance when using the result in consecutive matches.
%%
%% When using `unicode'/`UTF-8' as input for the subject or the
%% expression/pattern itself, pre-compilation is mandatory!
%% @end
%%------------------------------------------------------------------------------
-spec compile(iodata() | unicode:charlist(), boolean()) ->
                     {ok, mp()} | {error, term()}.
compile(Expr, IsUnicode) ->
    Opts = if IsUnicode -> [unicode]; true -> [] end,
    case convert(to_list(Expr, IsUnicode), [], Opts) of
        {ok, MP} -> {ok, {?MODULE, MP}};
        Error    -> Error
    end.

%%------------------------------------------------------------------------------
%% @doc
%% Executes an expression/pattern matching, returning `match' or `nomatch'. The
%% expression/pattern can be given either as `iodata()' in which case it is
%% automatically compiled (as by {@link glob:compile/1,2}) and executed, or as a
%% pre-compiled `mp()' in which case it is executed against the subject
%% directly.
%%
%% If the expression/pattern was previously compiled with the `IsUnicode=true',
%% `Subject' should be provided as a valid Unicode `charlist()', otherwise any
%% `iodata()' will do.
%%
%% When compilation is involved, the exception `badarg' is thrown if a
%% compilation error occurs. Call {@link glob:compile/1,2} to get information
%% about the error in the expression/pattern.
%% @end
%%------------------------------------------------------------------------------
-spec run(iodata() | unicode:charlist(), iodata() | mp()) -> match | nomatch.
run(Subject, Expr) ->
    try
        match(Subject, Expr)
    catch
        error:{badmatch, _} -> error(badarg)
    end.

%%------------------------------------------------------------------------------
%% @doc
%% Similar to {@link run/2} but returns a `boolean' indicating whether `Subject'
%% matches `Expr'.
%%
%% When compilation is involved, the exception `badmatch' is thrown if a
%% compilation error occurs. Call {@link glob:compile/1,2} to get information
%% about the error in the expression/pattern.
%% @end
%%------------------------------------------------------------------------------
-spec matches(iodata() | unicode:charlist(), iodata() | mp()) -> boolean().
matches(Subject, Expr) -> match(Subject, Expr) =:= match.

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
match(Subject, {?MODULE, MP}) ->
    re:run(Subject, MP, [{capture, none}]);
match(Subject, Expr) ->
    {ok, Compiled} = compile(Expr),
    match(Subject, Compiled).

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
convert([], Acc, Opts) ->
    re:compile([$^ | lists:reverse([$$ | Acc])], Opts ++ ?COMPILE_OPTS);
convert([$* | Rest], Acc, Opts) ->
    convert(Rest, [$* | [$. | Acc]], Opts);
convert([$? | Rest], Acc, Opts) ->
    convert(Rest, [$. | Acc], Opts);
convert([$\\], _Acc, _Opts) ->
    {error, escape_sequence_at_end_of_pattern};
convert([$\\ | [C | Rest]], Acc, Opts) ->
    convert(Rest, [C | [$\\ | Acc]], Opts);
convert([$[ | [$! | Rest]], Acc, Opts) ->
    convert_character_class(Rest, [$^ | [$[ | Acc]], Opts);
convert([$[ | Rest], Acc, Opts) ->
    convert_character_class(Rest, [$[ | Acc], Opts);
convert([C | Rest], Acc, Opts) ->
    convert(Rest, escape(C, Acc), Opts).

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
convert_character_class([], _Acc, _Opts) ->
    {error, non_terminated_character_class};
convert_character_class([$\\], _Acc, _Opts) ->
    {error, escape_sequence_at_end_of_pattern};
convert_character_class([$\\ | [C | Rest]], Acc, Opts) ->
    convert_character_class(Rest, [C | [$\\ | Acc]], Opts);
convert_character_class([$] | Rest], Acc, Opts) ->
    convert(Rest, [$] | Acc], Opts);
convert_character_class([C | Rest], Acc, Opts) ->
    convert_character_class(Rest, [C | Acc], Opts).

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
escape($^, Acc) -> [$^ | [$\\ | Acc]];
escape($$, Acc) -> [$$ | [$\\ | Acc]];
escape($., Acc) -> [$. | [$\\ | Acc]];
escape($|, Acc) -> [$| | [$\\ | Acc]];
escape($(, Acc) -> [$( | [$\\ | Acc]];
escape($), Acc) -> [$) | [$\\ | Acc]];
escape($+, Acc) -> [$+ | [$\\ | Acc]];
escape(${, Acc) -> [${ | [$\\ | Acc]];
escape($}, Acc) -> [$} | [$\\ | Acc]];
escape(C, Acc)  -> [C | Acc].

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
to_list(Data, true) ->
    unicode:characters_to_list(Data);
to_list(Bin, false) when is_binary(Bin) ->
    binary_to_list(Bin);
to_list(IoData, false) ->
    to_list(iolist_to_binary(IoData), false).
