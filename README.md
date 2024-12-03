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