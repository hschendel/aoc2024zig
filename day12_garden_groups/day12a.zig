const std = @import("std");
const grid = @import("util/grid.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const map = try grid.Grid.init(allocator, args[1]);
    defer map.uninit(allocator);

    var regions = std.ArrayList(Region).init(allocator);
    defer regions.deinit();

    var map_to_region = try allocator.alloc(?usize, map.width * map.height);
    for (map_to_region, 0..) |_, i| {
        map_to_region[i] = null;
    }
    defer allocator.free(map_to_region);

    var total_fence_price: u32 = 0;

    for (0..map.width) |x| {
        for (0..map.height) |y| {
            const plot_plant = map.mustGet(x, y);

            if (map_to_region[y * map.width + x] == null) {
                const region_idx = regions.items.len;
                try regions.append(Region {.plant = plot_plant });
                var region = &regions.items[region_idx];
                mark_region(@constCast(&map), &map_to_region, region_idx, region,x, y);
                std.debug.print("Region of {c} plants with price {d} * {d} = {d}\n", .{region.plant, region.area, region.perimeter, region.area * region.perimeter});
                total_fence_price += region.fence_price();
            }
        }
    }

    std.debug.print("{d}\n", .{total_fence_price});
}

const Region = struct {
    perimeter: u32 = 0,
    area: u32 = 0,
    plant: u8,

    fn fence_price(self: Region) u32 {
        return self.area * self.perimeter;
    }
};

const Boundaries = struct {
    start: usize,
    end: usize,
};

fn mark_region(map: *grid.Grid, map_to_region: *[]?usize, region_idx: usize, region: *Region, x: usize, y: usize) void {
    if (x >= map.width or y >= map.height) {
        return;
    }
    if (map_to_region.*[y * map.width + x] != null) {
        return;
    } else {
        const region_plant = region.plant;
        const plot_plant = map.mustGet(x, y);
        if (plot_plant != region_plant) {
            return;
        }
        map_to_region.*[y * map.width + x] = region_idx;
        region.area += 1;
        if (y > 0) {
            mark_region(map, map_to_region, region_idx, region, x, y-1);
            if (map.mustGet(x, y-1) != region_plant) {
                region.perimeter += 1;
            }
        } else {
            region.perimeter += 1;
        }
        if ((y+1) < map.height) {
            mark_region(map, map_to_region, region_idx, region, x, y+1);
            if (map.mustGet(x, y+1) != region_plant) {
                region.perimeter += 1;
            }
        } else {
            region.perimeter += 1;
        }
        if (x > 0) {
            mark_region(map, map_to_region, region_idx, region, x-1, y);
            if (map.mustGet(x-1, y) != region_plant) {
                region.perimeter += 1;
            }
        } else {
            region.perimeter += 1;
        }
        if ((x+1) < map.width) {
            mark_region(map, map_to_region, region_idx, region, x+1, y);
            if (map.mustGet(x+1, y) != region_plant) {
                region.perimeter += 1;
            }
        } else {
            region.perimeter += 1;
        }
    }
}