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
%%%=============================================================================

-module(glob_tests).

-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").

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

-define(PROPER_OPTS, [long_result, verbose, {numtests, 5000}]).

%%%=============================================================================
%%% TESTS
%%%=============================================================================

replace_nth_test() ->
    ?assertEqual("tello", replace_nth("Hello", 1, $t)),
    ?assertEqual("Htllo", replace_nth("Hello", 2, $t)),
    ?assertEqual("Hetlo", replace_nth("Hello", 3, $t)),
    ?assertEqual("Helto", replace_nth("Hello", 4, $t)),
    ?assertEqual("Hellt", replace_nth("Hello", 5, $t)).

simple_test() ->
    ?assert(glob:matches("", "")),
    ?assert(glob:matches("", "*")),
    ?assert(not glob:matches("", "?")),
    ?assert(not glob:matches("", "abc")),
    ?assert(glob:matches([$\\], [$\\, $\\])),
    ?assert(glob:matches([$*], [$\\, $*])),
    ?assert(glob:matches([$?], [$\\, $?])).

compile_errors_test() ->
    ?assertMatch({error, _}, glob:compile("abc\\")),
    ?assertMatch({error, _}, glob:compile("abc[")).

wikipedia_test() ->
    ?assert(glob:matches("Cat", "?at")),
    ?assert(glob:matches("cat", "?at")),
    ?assert(glob:matches("Bat", "?at")),
    ?assert(glob:matches("bat", "?at")),
    ?assert(not glob:matches("at", "?at")),
    ?assert(glob:matches("Law", "Law*")),
    ?assert(glob:matches("Laws", "Law*")),
    ?assert(glob:matches("Lawyer", "Law*")),
    ?assert(glob:matches("Law", "*Law*")),
    ?assert(glob:matches("GrokLaw", "*Law*")),
    ?assert(glob:matches("Lawyer", "*Law*")),
    ?assert(glob:matches("Cat", "[CB]at")),
    ?assert(glob:matches("Bat", "[CB]at")),
    ?assert(not glob:matches("cat", "[CB]at")),
    ?assert(not glob:matches("bat", "[CB]at")),
    ?assert(not glob:matches("Cat", "[!CB]at")),
    ?assert(not glob:matches("Bat", "[!CB]at")),
    ?assert(glob:matches("cat", "[!CB]at")),
    ?assert(glob:matches("bat", "[!CB]at")),
    ?assert(glob:matches("Letter0", "Letter[0-9]")),
    ?assert(glob:matches("Letter1", "Letter[0-9]")),
    ?assert(not glob:matches("Letter", "Letter[0-9]")),
    ?assert(not glob:matches("Letters", "Letter[0-9]")),
    ?assert(glob:matches("Letter1", "Letter[!3-5]")),
    ?assert(glob:matches("Letter2", "Letter[!3-5]")),
    ?assert(not glob:matches("Letter", "Letter[!3-5]")),
    ?assert(not glob:matches("Letter3", "Letter[!3-5]")),
    ?assert(not glob:matches("Letter4", "Letter[!3-5]")),
    ?assert(not glob:matches("Letter5", "Letter[!3-5]")).

escape_test() ->
    ?assert(glob:matches("!^$.|()+{}\\[-]*?", "!^$.|()+{}\\\\\\[\\-\\]\\*\\?")),
    ?assert(glob:matches("!", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("^", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("$", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches(".", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("|", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("(", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches(")", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("+", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("^", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("{", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("}", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("\\", "[\\!^$.|()+{}\\\\\\[\-\\]\\*\\?]")),
    ?assert(glob:matches("[", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("-", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("]", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("*", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")),
    ?assert(glob:matches("?", "[\\!^$.|()+{}\\\\\\[\\-\\]\\*\\?]")).

empty_expr_test() ->
    qc(?FORALL(
          Subject, non_empty_str(),
          begin not glob:matches(Subject, "") end)).

exact_match_test() ->
    qc(?FORALL(
          Subject,
          str(),
          begin glob:matches(Subject, Subject) end)).

single_question_mark_test() ->
    qc(?FORALL(
          Subject,
          non_special_char(),
          begin glob:matches([Subject], "?") end)).

single_star_test() ->
    qc(?FORALL(
          Subject,
          str(),
          begin glob:matches(Subject, "*") end)).

leading_question_mark_test() ->
    qc(?FORALL(
          Subject,
          non_empty_str(),
          begin glob:matches(Subject, [$? | tl(Subject)]) end)).

leading_star_test() ->
    qc(?FORALL(
          Subject,
          non_empty_str(),
          begin
              case length(Subject) > 1 of
                  true ->
                      glob:matches(Subject, [$* | tl(tl(Subject))]);
                  false ->
                      glob:matches(Subject, [$* | tl(Subject)])
              end
          end)).

random_question_mark_test() ->
    qc(?FORALL(
          {Subject, N},
          ?SUCHTHAT(
             {Subject, N},
             {non_empty_str(), pos_integer()},
             N =< length(Subject)),
          begin glob:matches(Subject, replace_nth(Subject, N, $?)) end)).

random_star_test() ->
    qc(?FORALL(
          {Subject, N},
          ?SUCHTHAT(
             {Subject, N},
             {non_empty_str(), pos_integer()},
             N =< length(Subject)),
          begin glob:matches(Subject, replace_nth(Subject, N, $*)) end)).

character_class_matching_test() ->
    qc(?FORALL(
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
          end)).

character_class_not_matching_test() ->
    qc(?FORALL(
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
          end)).

unicode_test() ->
    {ok, MP1} = glob:compile(<<"*ä?ö"/utf8>>, true),
    {ok, MP2} = glob:compile("*ä*ö", true),
    ?assert(glob:matches("äüö", MP1)),
    ?assert(glob:matches("äüö", MP2)).

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
replace_nth(String, N, Replacement) ->
    string:substr(String, 1, N - 1)
        ++ [Replacement | string:substr(String, N + 1)].

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
qc(Block) -> ?assert(proper:quickcheck(Block, ?PROPER_OPTS)).
