![Build Status](https://github.com/lindenbaum/glob/.github/workflows/test.yml/badge.svg?branch=master)
[![Old Build Status (TRAVIS)](https://travis-ci.org/lindenbaum/glob.png?branch=master)](https://travis-ci.org/lindenbaum/glob)

glob
====

A library application to work with `glob` patterns. Now also available on
[hex.pm](https://hex.pm/packages/glob).

Syntax
------

This implementation provides the same `glob` pattern facilities as `bash`
(partly from [Wikipedia](https://en.wikipedia.org/wiki/Glob_%28programming%29)):
 * `?`: Match exactly one unknown character.
 * `*`: Match any number of unknown characters from the position in which it
        appears to the end of the subject also match any number of unknown
        characters (regardless of the position where it appears, including at
        the start and/or multiple times.
 * `[characters]`: Match a character as part of a group of characters.
 * `[!characters]`: Match any character but the ones specified.
 * `[character-charcter]`: Match a character as part of a character range.
 * `[!character-charcter]`: Match any character but the range specified.

The underlying implementation utilizes the `re` module which means that a
given `glob` pattern will be converted into a regular expression. For
convenience this module features an API that is quite similar to the `re`
module. Although, the shorthand `glob:matches/1` enables a more intuitive
and simple experience.

As `glob` relies on `re` it offers support for Unicode input. However,
this support comes with the same restrictions known from `re`.

Example
-------

Simple matches:
```erlang
    false = glob:matches("Hello World", "Hello"),
    true = glob:matches("Hello World", "*"),
    true = glob:matches("Hello World", "Hello*Wo?l[d]"),
```

Match unicode input for expression/pattern and subject:
```erlang
    {ok, MP} = glob:compile(<<"*ä?ö"/utf8>>, true),
    true = glob:matches("äüö", MP),
```
