# Advent of Code 2024 in Zig

## Usage

All programs expect the input file as their first parameter, so they can run e.g. like

```
$ zig run day01a.zig -- test.txt
11
```

## Day 01 - Historian Hysteria

As I am totally new to Zig I needed a bit to get things running. [Zig Guide](https://zig.guide/) was
very helpful. This year I did not do much low level coding, so I caught myself complaining about how
much effort it could be to parse a simple file. Yet compared to C this all feels good ;-)

## Day 02 - Red-nosed Reports

I like Zig's error handling, it is close to Go, but with less boilerplate.

## Day 03 - Mull it over

String processing is like in Go, not too comfortable, but clearly more comfortable than C. Also
the range switching using `...` is nice.

## Day 04 - Ceres Search

Scanning grids is an AoC all-time favorite. A good opportunity to learn about Zig's import mechanism by
extracting "library" code for that. Quite frustrating that `@import("../util/grid.zig")` does not work,
as for some reason I could not follow Zig only allows you to import from folders below the main program's
folder. So no multiple executables in different sub-folders as in Go.

Instead of moving all programs into the root folder I am now using symlinks to bypass this logic and have
a shared `util` library folder.

Also, I stumbled over `for (0..width-1)` being exclusive at the right end :-D

## Day 05 - Print Queue

This day seemed to play into Zig's strengths. The `AutoHashMap` and the fact that plain structs
can be used as keys worked out really well.