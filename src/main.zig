const std = @import("std");
const DB = @import("db.zig");

const c = @cImport({
    @cInclude("sqlite3.h");
});

pub const log_level: std.log.Level = .info;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const db = DB{
        .alloc = arena_alloc,
        .db_file = "db.sqlite",
    };

    try db.open();
    defer db.close() catch |err| {
        std.log.err("{}", .{err});
    };

    try db.create_trs_table();

    try db.add_tr("juan", "pancho", 100);
    try db.add_tr("juan", "pancho", 200);
    try db.add_tr("pancho", "juan", 150);

    try db.print_trs();
}
