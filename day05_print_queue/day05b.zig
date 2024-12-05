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
    var phase_order: bool = true;
    var page_order = std.AutoHashMap(PageOrderEntry, bool).init(allocator);
    defer page_order.deinit();
    var middle_sum: u32 = 0;
    var update = std.ArrayList(u32).init(allocator);
    defer update.deinit();

    while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
        if (phase_order) {
            if (line.len == 0) {
                phase_order = false;
                continue;
            }
            var it = std.mem.tokenizeScalar(u8, line, '|');
            const page1 = try std.fmt.parseInt(u32, it.next().?, 10);
            const page2 = try std.fmt.parseInt(u32, it.next().?, 10);
            try page_order.put(PageOrderEntry{.left = page1, .right = page2}, true);
        } else {
            var it = std.mem.tokenizeScalar(u8, line, ',');
            update.shrinkRetainingCapacity(0);
            while (it.next()) |s| {
                const page = try std.fmt.parseInt(u32, s, 10);
                try update.append(page);
            }
            var ordered = true;
            order_check_loop: for (update.items, 0..) |page1, i| {
                for (update.items[i+1..]) |page2| {
                    const rule = page_order.get(PageOrderEntry{.left = page2, .right = page1});
                    if (rule != null) {
                        ordered = false;
                        break :order_check_loop;
                    }
                }
            }
            if (ordered) {
                continue;
            }
            std.mem.sort(u32, update.items, page_order, page_before);
            const middle_page = update.items[update.items.len / 2];
            middle_sum += middle_page;
        }
    }

    std.debug.print("{d}\n", .{middle_sum});
}

const PageOrderEntry = struct {
    left: u32,
    right: u32
};

fn page_before(page_order: std.AutoHashMap(PageOrderEntry, bool), left: u32, right: u32) bool {
    return page_order.get(PageOrderEntry{.left = right, .right = left}) == null;
}