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
    const width: usize = if (is_test) 11 else 101;
    const height: usize = if (is_test) 7 else 103;

    var robots = std.ArrayList(Robot).init(allocator);
    defer robots.deinit();

    while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |_| {
        if (Robot.parse(&line_buf)) |robot| {
            try robots.append(robot);
        }
    }

    var seconds: i32 = 0;
    var screen = try RobotScreen.init(allocator, width, height);
    defer screen.deinit();

    while(true) {
        screen.setRobots(robots.items);
        if (screen.hasStraightXLine(20)) {
            try screen.print(seconds);
            return;
        }
        robots_second(robots, @intCast(width), @intCast(height));
        seconds += 1;
    }
}

fn robots_second(robots: std.ArrayList(Robot), width: i32, height: i32) void {
    for(robots.items) |*robot| {
        robot.* = robot.simulate_seconds(width, height, 1);
    }
}

const RobotScreen = struct {
    width: usize,
    height: usize,
    screen: []u8,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, width: usize, height: usize) !RobotScreen {
        return RobotScreen{
            .width = width,
            .height = height,
            .screen = try allocator.alloc(u8, (width+1) * height),
            .allocator = allocator,
        };
    }

    fn deinit(self: *RobotScreen) void {
        self.allocator.free(self.screen);
    }

    fn print(self: *RobotScreen, seconds: i32) !void {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("\u{001b}[{d};0H", .{self.height+1});
        try stdout.print("SECONDS: {d}\n{s}", .{seconds, self.screen});
    }

    fn reset(self: *RobotScreen) void {
        var y: usize = 0;
        var pos: usize = 0;
        while (y < self.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.width) : (x += 1) {
                self.screen[pos] = ' ';
                pos += 1;
            }
            self.screen[pos] = '\n';
            pos += 1;
        }
    }

    fn setRobots(self: *RobotScreen, robots: []Robot) void {
        self.reset();
        for(robots) |robot| {
            self.screen[@as(usize, @intCast(robot.py)) * (self.width+1) + @as(usize, @intCast(robot.px))] = '#';
        }
    }

    fn hasStraightXLine(self: *RobotScreen, min_length: usize) bool {
        for(0..self.height) |y| {
            var count: usize = 0;
            for(0..self.width) |x| {
                if (self.screen[y * (self.width+1) + x] == '#') {
                    count += 1;
                } else {
                    count = 0;
                }
                if (count >= min_length) {
                    return true;
                }
            }
        }
        return false;
    }
};

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

const Balance = struct {
    height: usize,
    center_x: usize,
    balance: []isize,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Balance {
        var self = Balance {
            .height = height,
            .center_x = @divFloor(width, 2),
            .balance = try allocator.alloc(isize, height),
            .allocator = allocator,
        };
        self.reset();
        return self;
    }

    fn deinit(self: Balance) void {
        self.allocator.free(self.balance);
    }

    fn reset(self: *Balance) void {
        for (self.balance) |*v| {
            v.* = 0;
        }
    }

    fn set(self: *Balance, robots: []Robot) void {
        self.reset();
        for (robots) |robot| {
            const y: usize = @intCast(robot.py);
            const x: isize = @intCast(robot.px);
            self.balance[y] += x;
        }
    }

    fn all_balanced(self: Balance) bool {
        for (self.balance) |v| {
            if (v != 0) {
                return false;
            }
        }
        return true;
    }
};