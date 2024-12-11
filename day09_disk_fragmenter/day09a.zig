const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();
    const file_reader = file.reader();
    var blocks = std.ArrayList(?u32).init(allocator);
    defer blocks.deinit();

    var file_id: u32 = 0;
    var expect_file = true;
    while (file_reader.readByte()) |digit| {
        const count: usize = switch (digit) {
            '0'...'9' => digit - '0',
            else => unreachable
        };
        const block_value = if (expect_file) file_id else null;
        for(0..count) |_| {
            try blocks.append(block_value);
        }
        if (expect_file) {
            file_id += 1;
        }
        expect_file = !expect_file;
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    var next_free: usize = 0;
    while (next_free < blocks.items.len) {
        while (next_free < blocks.items.len and blocks.items[next_free] != null) {
            next_free += 1;
        }
        if (next_free >= blocks.items.len) {
            break;
        }
        blocks.items[next_free] = blocks.items[blocks.items.len-1];
        blocks.shrinkRetainingCapacity(blocks.items.len-1);
    }

    var check_sum: u64 = 0;
    for (blocks.items, 0..) |pos_block_id, pos| {
        if (pos_block_id) |id| {
            check_sum += id * pos;
        }
    }

    std.debug.print("{d}\n", .{check_sum});
}