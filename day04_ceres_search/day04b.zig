const std = @import("std");
const grid = @import("util/grid.zig");
const eql = std.mem.eql;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const plan = try grid.Grid.init(allocator, args[1]);
    defer plan.uninit(allocator);

    var crosses: usize = 0;

    for (0..plan.width) |ux| {
        const x: isize = @intCast(ux);
        for (0..plan.height) |uy| {
            const y: isize = @intCast(uy);
            if (is_xmas_cross(plan, x, y)) {
                crosses += 1;
            }
        }
    }

    std.debug.print("{d}\n", .{crosses});
}

fn is_xmas_cross(plan: grid.Grid, x: isize, y: isize) bool {
    const c = plan.get(x, y).?;
    if (c != 'A') {
        return false;
    }
    const ul = plan.get(x-1, y-1);
    const br = plan.get(x+1, y+1);
    const bl = plan.get(x-1, y+1);
    const ur = plan.get(x+1, y-1);
    if (ul == null or br == null or bl == null or ur == null) {
        return false;
    }
    return (ul.? == 'M' and br.? == 'S' or ul.? == 'S' and br.? == 'M')
        and (bl.? == 'M' and ur.? == 'S' or bl.? == 'S' and ur.? == 'M');
}