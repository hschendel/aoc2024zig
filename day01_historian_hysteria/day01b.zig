const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const file_name = args[1];
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    var line_buf = [_]u8{0} ** 100;
    var list_left = std.ArrayList(i32).init(allocator);
    defer list_left.deinit();
    var right_map = std.AutoHashMap(i32, i32).init(allocator);
    defer right_map.deinit();

    while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');
        var left: ?i32 = null;
        var right: ?i32 = null;
        while (it.next()) |v| {
            if (v.len == 0) {
                continue;
            }
            if (left == null) {
                left = try std.fmt.parseInt(i32, v, 10);
                continue;
            }
            right = try std.fmt.parseInt(i32, v, 10);
            break;
        }
        try list_left.append(left.?);
        const count = (right_map.get(right.?) orelse 0) + 1;
        try right_map.put(right.?, count);
    }

    var score: i32 = 0;
    for (list_left.items) |left| {
        const count_right = right_map.get(left) orelse 0;
        score += left * count_right;
    }

    std.debug.print("{d}\n", .{score});
}
