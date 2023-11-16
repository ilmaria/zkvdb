const std = @import("std");
const c = @cImport({
    @cInclude("rocksdb.h");
});

pub fn main() !void {
    var options = c.rocksdb_options_create();
    c.rocksdb_options_optimize_level_style_compaction(options, 0);
    // create the DB if it's not already present
    c.rocksdb_options_set_create_if_missing(options, 1);

    std.fs.cwd().makeDir("simple_example_db") catch {};

    std.debug.print("opening db\n", .{});
    var err: ?[*:0]u8 = null;
    const db = c.rocksdb_open(options, "./simple_example_db", &err);
    assertNoErr(err);
    defer c.rocksdb_close(db);

    std.debug.print("writing to db\n", .{});
    const writeoptions = c.rocksdb_writeoptions_create();
    const key = "my_key";
    const value = "my_value";
    c.rocksdb_put(db, writeoptions, key, key.len, value, value.len + 1, &err);
    assertNoErr(err);

    std.debug.print("reading from db\n", .{});
    const readoptions = c.rocksdb_readoptions_create();
    var len: usize = 0;
    var read_value = c.rocksdb_get(db, readoptions, key, key.len, &len, &err);
    assertNoErr(err);
    defer c.rocksdb_free(read_value);
    if (!std.mem.eql(u8, std.mem.span(read_value), value)) {
        std.debug.print("error: read_value != value: {s} != {s}", .{ read_value, value });
        @panic("");
    }
    std.debug.print("read_value == {s}\n", .{read_value});

    return std.process.cleanExit();
}

fn assertNoErr(err: ?[*:0]u8) void {
    if (err) |msg| {
        std.debug.print("{s}", .{msg});
        @panic("");
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
