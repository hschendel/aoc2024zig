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
    var min_tokens: u32 = 0;

    var eq = Equation{};

    while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |_| {
        min_tokens += try eq.parse_line(&line_buf);
    }

    std.debug.print("{d}\n", .{min_tokens});
}

const Equation = struct {
    a_offset_x: u32 = 0,
    a_offset_y: u32 = 0,
    b_offset_x: u32 = 0,
    b_offset_y: u32 = 0,
    prize_x: u32 = 0,
    prize_y: u32 = 0,
    
    fn parse_line(self: *Equation, line_buf: []const u8) !u32 {
        if (std.mem.startsWith(u8, line_buf, "Button A:")) {
            self.a_offset_x = try parse_num(line_buf, "X+");
            self.a_offset_y = try parse_num(line_buf, "Y+");
            return 0;
        } else if (std.mem.startsWith(u8, line_buf, "Button B:")) {
            self.b_offset_x = try parse_num(line_buf, "X+");
            self.b_offset_y = try parse_num(line_buf, "Y+");
            return 0;
        } else if (std.mem.startsWith(u8, line_buf, "Prize:")) {
            self.prize_x = try parse_num(line_buf, "X=");
            self.prize_y = try parse_num(line_buf, "Y=");
            const min_cost = self.solve();
            std.debug.print("A X+{d} Y+{d}, B X+{d}, Y+{d}, Prize X={d}, Y={d} => {any}\n",
                .{self.a_offset_x, self.a_offset_y, self.b_offset_x, self.b_offset_y, self.prize_x, self.prize_y, min_cost});
            if (min_cost == null) {
                return 0;
            } else {
                return min_cost.?;
            }
        }
        return 0;
    }

    fn parse_num(line_buf: []const u8, marker: []const u8) !u32 {
        if(std.mem.indexOf(u8, line_buf, marker)) |marker_pos| {
            const start = marker_pos + marker.len;
            var end = start;
            for (line_buf[start..]) |c| {
                switch (c) {
                    '0'...'9' => end += 1,
                    else => break
                }
            }
            if (end > start) {
                return std.fmt.parseInt(u32, line_buf[start..end], 10);
            }
        }
        return std.fmt.ParseIntError.InvalidCharacter;
    }

    fn solve(self: *const Equation) ?u32 {
        const closest_b_for_x = @divFloor(self.prize_x, self.b_offset_x);
        const closest_b_for_y = @divFloor(self.prize_y, self.b_offset_y);
        var b: u32 = if (closest_b_for_x <= closest_b_for_y) closest_b_for_x else closest_b_for_y;
        while(true) {
            const xb = b * self.b_offset_x;
            const a = @divFloor(self.prize_x - xb, self.a_offset_x);
            const x = a * self.a_offset_x + b * self.b_offset_x;
            const y = a * self.a_offset_y + b * self.b_offset_y;
            if (x == self.prize_x and y == self.prize_y) {
                return 3 * a + b;
            }
            if (b == 0) {
                break;
            }
            b -= 1;
        }
        return null;
    }
};