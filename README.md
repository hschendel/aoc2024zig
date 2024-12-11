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

## Day 06 - Guard Gallivant

I failed miserably on part two. There is still a bug in my code, and I did not want to spend the whole day
chasing it.

## Day 07 - Bridge Repair

Funny side note: Lazy thinker that I am, I implemented `concat` first using `std.fmt.allocPrint`, having to 
allocate and free. It was shockingly slow.

## Day 08 - Resonant Collinearity

I used an AutoHashMap of ArrayLists to group the antennae, and that took a bit to get used to in Zig.
In the end the code looks a bit like Go with the additional caveat that I need to call `deinit()` on every list.
Also, I do not yet understand why I have to use `@constCast` for this line to compile:

```
try putAntinodes(@constCast(&map), pos1, pos2, @constCast(&antinodes));
```

But I will do my homework ;)

## Day 09 - Disk Fragmenter

Zig's loop constructs do not feel well-rounded to me. Try to iterate backwards over an array using a `usize`
index.

## Day 10 - Hoof It

I did only have 30 minutes and could not manage to get my solution to compile in that timebox.

## Day 11 - Plutonian Pebbles

Classic AoC. You start implementing a data structure in part one, and in part two it becomes obvious that this
would blow up your memory. Then you see that you would not have needed to store things in memory anyway. Then
you realize the thing is highly repetitive and add a lookup table :-D