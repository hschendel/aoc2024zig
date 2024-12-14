const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var line_buf = [_]u8{0} ** 100;

    const is_test = std.mem.eql(u8, "test.txt", args[1]);
    const width: i32 = if (is_test) 11 else 101;
    const height: i32 = if (is_test) 7 else 103;
    var quadrant_counts = [_]i32{0, 0, 0, 0};

    while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |_| {
        if (Robot.parse(&line_buf)) |robot| {
            const robot100 = robot.simulate_seconds(width, height, 100);
            if(robot100.quadrant(width, height)) |quadrant| {
                quadrant_counts[quadrant] += 1;   
            }
        }
    }
    
    std.debug.print("{d}\n", .{quadrant_counts[0] * quadrant_counts[1] * quadrant_counts[2] * quadrant_counts[3]});
}

const Robot = struct {
    px: i32 = 0,
    py: i32 = 0,
    vx: i32 = 0,
    vy: i32 = 0,

    fn parse(line_buf: []u8) ?Robot {
        var self = Robot{};
        var state: u8 = 0;
        for (line_buf) |c| {
            switch (state) {
                0 => {
                    if (c != 'p') {
                        return null;
                    }
                    state = 1;
                },
                1 => {
                    if (c != '=') {
                        return null;
                    }
                    state = 2;
                },
                2 => switch (c) {
                    '0'...'9' => self.px = self.px * 10 + @as(i32,@intCast(c)) - '0',
                    ',' => state = 3,
                    else => return null
                },
                3 => switch (c) {
                    '0'...'9' => self.py = self.py * 10 + @as(i32,@intCast(c)) - '0',
                    ' ' => state = 4,
                    else => return null
                },
                4 => if (c == 'v') {
                    state = 5;
                } else {
                    return null;
                },
                5 => if (c == '=') {
                    state = 6;
                } else {
                    return null;
                },
                6 => switch (c) {
                    '-' => state = 8,
                    '0'...'9' => {
                        self.vx = @as(i32,@intCast(c)) - '0';
                        state = 7;
                    },
                    else => return null
                },
                7 => switch (c) {
                    '0'...'9' => self.vx = self.vx * 10 + @as(i32,@intCast(c)) - '0',
                    ',' => state = 9,
                    else => return null
                },
                8 => switch (c) {
                    '0'...'9' => self.vx = self.vx * 10 + @as(i32,@intCast(c)) - '0',
                    ',' => {
                        self.vx *= -1;
                        state = 9;
                    },
                    else => return null
                },
                9 => switch (c) {
                    '-' => state = 11,
                    '0'...'9' => {
                        self.vy = @as(i32,@intCast(c)) - '0';
                        state = 10;
                    },
                    else => return null
                },
                10 => switch (c) {
                    '0'...'9' => self.vy = self.vy * 10 + @as(i32,@intCast(c)) - '0',
                    else => return self
                },
                11 => switch (c) {
                    '0'...'9' => self.vy = self.vy * 10 + @as(i32,@intCast(c)) - '0',
                    else => {
                        self.vy *= -1;
                        return self;
                    }
                },
                else => unreachable
            }
        }
        return self;
    }

    fn simulate_seconds(self: Robot, width: i32, height: i32, seconds: i32) Robot {
        return Robot {
            .px = @mod(self.px + self.vx * seconds, width),
            .py = @mod(self.py + self.vy * seconds, height),
            .vx = self.vx,
            .vy = self.vy,
        };
    }

    fn quadrant(self: *const Robot, width: i32, height: i32) ?usize {
        const end_left = @divFloor(width, 2);
        const start_right = width - end_left;
        const end_top = @divFloor(height, 2);
        const start_bottom = height - end_top;
        if (self.px < end_left) {
            if (self.py < end_top) {
                return 0;
            } else if(self.py >= start_bottom) {
                return 2;
            } else {
                return null;
            }
        } else if (self.px >= start_right) {
            if (self.py < end_top) {
                return 1;
            } else if(self.py >= start_bottom) {
                return 3;
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

    fn print (self: *const Robot) void {
        std.debug.print("p={d},{d}, v={d},{d}\n", .{self.px, self.py, self.vx, self.vy});
    }
};