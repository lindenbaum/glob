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

-module(glob_tests).

-include_lib("eunit/include/eunit.hrl").

%%%=============================================================================
%%% TESTS
%%%=============================================================================

simple_test() ->
    ?assert(glob:matches("", "")),
    ?assert(glob:matches("", "*")),
    ?assert(not glob:matches("", "?")),
    ?assert(not glob:matches("", "abc")),
    ?assert(not glob:matches("lala1", "[0-9]*")),
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

unicode_test() ->
    {ok, MP1} = glob:compile(<<"*ä?ö"/utf8>>, true),
    {ok, MP2} = glob:compile("*ä*ö", true),
    ?assert(glob:matches("äüö", MP1)),
    ?assert(glob:matches("äüö", MP2)).
