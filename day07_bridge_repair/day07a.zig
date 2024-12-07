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

    var calibration_sum: u64 = 0;

    while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
        const eq = try Equation.parse(allocator, line);
        defer eq.deinit(allocator);

        if (eq.can_be_made_true()) {
            calibration_sum += eq.result;
        }
    }

    std.debug.print("{}\n",.{calibration_sum});
}

const Equation = struct {
    result: u64,
    numbers: []u64,

    pub fn parse(allocator: std.mem.Allocator, line: []u8) !Equation {
        var numbers_list = std.ArrayList(u64).init(allocator);
        defer numbers_list.deinit();
        var result_read = false;
        var result: u64 = 0;
        var it = std.mem.splitScalar(u8, line, ' ');
        while(it.next()) |v| {
            if (!result_read) {
                if (v.len < 2 or v[v.len-1] != ':') {
                    return error.ExpectedResult;
                }
                result = try std.fmt.parseInt(u64, v[0..v.len-1], 10);
                result_read = true;
                continue;
            }

            try numbers_list.append(try std.fmt.parseInt(u64, v, 10));
        }

        const numbers = try allocator.alloc(u64, numbers_list.items.len);
        std.mem.copyForwards(u64, numbers, numbers_list.items);
        return Equation {.result = result, .numbers = numbers};
    }

    pub fn deinit(self: Equation, allocator: std.mem.Allocator) void {
        allocator.free(self.numbers);
    }

    pub fn can_be_made_true(self: Equation) bool {
        if (self.numbers.len == 0) {
            return false;
        }
        return self.can_be_made_true_rec(self.numbers[0], 1);
    }

    fn can_be_made_true_rec(self: Equation, result_so_far: u64, i: usize) bool {
        if (i >= self.numbers.len) {
            return result_so_far == self.result;
        }
        return self.can_be_made_true_rec(result_so_far + self.numbers[i], i + 1)
            or self.can_be_made_true_rec(result_so_far * self.numbers[i], i + 1);
    }

    const ParseError = error {
        ExpectedResult,
    };
};