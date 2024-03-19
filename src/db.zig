const std = @import("std");

const c = @cImport({
    @cInclude("sqlite3.h");
});

const Self = @This();

alloc: std.mem.Allocator,
db_file: [*c]const u8,

var db_p: ?*c.sqlite3 = undefined;

pub fn open(self: *const Self) !void {
    if (c.sqlite3_open(self.db_file, &db_p) != c.SQLITE_OK) {
        std.log.err(
            "Error opening the database: {s}\n{s}",
            .{ self.db_file, c.sqlite3_errmsg(db_p) },
        );
        return error.dbError;
    } else {
        std.log.info(
            "Successfully opened the database: {s}",
            .{self.db_file},
        );
    }
}

pub fn close(self: *const Self) !void {
    if (c.sqlite3_close(db_p) != c.SQLITE_OK) {
        std.log.err(
            "Error closing the database: {s}\n{s}",
            .{ self.db_file, c.sqlite3_errmsg(db_p) },
        );
        return error.dbError;
    } else {
        std.log.info(
            "Successfully closed the database: {s}",
            .{self.db_file},
        );
    }
}

pub fn create_trs_table(self: *const Self) !void {
    _ = self;
    const sql =
        \\CREATE TABLE IF NOT EXISTS transactions(
        \\t_id INTEGER PRIMARY KEY AUTOINCREMENT,
        \\t_from TEXT NOT NULL ,
        \\t_to TEXT NOT NULL,
        \\t_amount INTEGER NOT NULL
        \\);
    ;
    if (c.sqlite3_exec(db_p, sql, null, null, null) != c.SQLITE_OK) {
        std.log.err(
            "Error creating transactions table\n{s}",
            .{c.sqlite3_errmsg(db_p)},
        );
        return error.dbError;
    }
}

const Tr = struct {
    id: i32,
    from: []const u8,
    to: []const u8,
    amount: i32,
};

pub fn add_tr(
    self: *const Self,
    from: []const u8,
    to: []const u8,
    amount: i64,
) !void {
    const sql = try std.fmt.allocPrintZ(
        self.alloc,
        "INSERT INTO transactions (t_from, t_to, t_amount) VALUES('{s}', '{s}', {d});",
        .{ from, to, amount },
    );
    if (c.sqlite3_exec(db_p, sql, null, null, null) != c.SQLITE_OK) {
        std.log.err(
            "Error executing sql statement\n{s}\n{s}",
            .{ sql, c.sqlite3_errmsg(db_p) },
        );
        return error.dbError;
    } else {
        std.log.info(
            "New transaction\n{s:>7}: {s}\n{s:>7}: {s}\n{s:>7}: {d}",
            .{ "from", from, "to", to, "amount", amount },
        );
    }
}

pub fn print_trs(self: *const Self) !void {
    _ = self;
    if (c.sqlite3_exec(db_p, "SELECT * FROM transactions", print_row, null, null) != c.SQLITE_OK) {
        std.log.err(
            "{s}",
            .{c.sqlite3_errmsg(db_p)},
        );
        return error.dbError;
    }
}

fn print_row(NotUsed: ?*anyopaque, argc: c_int, argv: [*c][*c]u8, azColName: [*c][*c]u8) callconv(.C) c_int {
    _ = NotUsed;
    _ = argc;
    _ = azColName;

    inline for (@typeInfo(Tr).Struct.fields, 0..) |field, i| {
        std.debug.print("{s:>7}: {s}\n", .{ field.name, argv[i] });
    }

    return 0;
}
