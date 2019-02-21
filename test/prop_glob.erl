%%%=============================================================================
%%%
%%%               |  o __   _|  _  __  |_   _       _ _   (TM)
%%%               |_ | | | (_| (/_ | | |_) (_| |_| | | |
%%%
%%% @copyright (C) 2015-2019, Lindenbaum GmbH
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
%%%=============================================================================

-module(prop_glob).

-include_lib("proper/include/proper.hrl").

-type str() :: [non_special_char()].
-type non_empty_str() :: [non_special_char(), ...].

%% everything without $!, $*, $?, $[, $\\, $] (the glob special characters)
-type non_special_char() :: 1..32 | 34..41 | 43..62 | 64..90 | 94..255.
%% an integer from the range $1-$5
-type one_to_five() :: 49..53.

-export_type([str/0,
              non_empty_str/0,
              non_special_char/0,
              one_to_five/0]).

%%%=============================================================================
%%% TESTS
%%%=============================================================================

prop_empty_expr() ->
    ?FORALL(
       Subject, non_empty_str(),
       begin not glob:matches(Subject, "") end).

prop_exact_match() ->
    ?FORALL(
       Subject,
       str(),
       begin glob:matches(Subject, Subject) end).

prop_single_question_mark() ->
    ?FORALL(
       Subject,
       non_special_char(),
       begin glob:matches([Subject], "?") end).

prop_single_star() ->
    ?FORALL(
       Subject,
       str(),
       begin glob:matches(Subject, "*") end).

prop_leading_question_mark() ->
    ?FORALL(
       Subject,
       non_empty_str(),
       begin glob:matches(Subject, [$? | tl(Subject)]) end).

prop_leading_star() ->
    ?FORALL(
       Subject,
       non_empty_str(),
       begin
           case length(Subject) > 1 of
               true ->
                   glob:matches(Subject, [$* | tl(tl(Subject))]);
               false ->
                   glob:matches(Subject, [$* | tl(Subject)])
           end
       end).

prop_random_question_mark() ->
    ?FORALL(
       {Subject, N},
       ?SUCHTHAT(
          {Subject, N},
          {non_empty_str(), pos_integer()},
          N =< length(Subject)),
       begin glob:matches(Subject, replace_nth(Subject, N, $?)) end).

prop_random_star() ->
    ?FORALL(
       {Subject, N},
       ?SUCHTHAT(
          {Subject, N},
          {non_empty_str(), pos_integer()},
          N =< length(Subject)),
       begin glob:matches(Subject, replace_nth(Subject, N, $*)) end).

prop_character_class_matching() ->
    ?FORALL(
       {{Subject, N}, I},
       {?SUCHTHAT(
           {Subject, N},
           {non_empty_str(), pos_integer()},
           N =< length(Subject)),
        one_to_five()},
       begin
           glob:matches(
             replace_nth(Subject, N, I),
             replace_nth(Subject, N, "[1-5]"))
       end).

prop_character_class_not_matching() ->
    ?FORALL(
       {{Subject, N}, I},
       {?SUCHTHAT(
           {Subject, N},
           {non_empty_str(), pos_integer()},
           N =< length(Subject)),
        one_to_five()},
       begin
           not glob:matches(
                 replace_nth(Subject, N, I),
                 replace_nth(Subject, N, "[!1-5]"))
       end).

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
replace_nth(String, N, Replacement) ->
    string:substr(String, 1, N - 1)
        ++ [Replacement | string:substr(String, N + 1)].
