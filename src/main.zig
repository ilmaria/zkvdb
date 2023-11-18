const std = @import("std");
const c = @cImport({
    @cInclude("rocksdb.h");
});

pub fn main() !void {
    var options = c.rocksdb_options_create();
    // Recommended settings from https://github.com/facebook/rocksdb/wiki/Setup-Options-and-Basic-Tuning#other-general-options
    c.rocksdb_options_set_max_background_jobs(options, 6);
    c.rocksdb_options_set_bytes_per_sync(options, 1048576);

    c.rocksdb_options_set_create_if_missing(options, 1);

    c.rocksdb_create_column_families;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var path_buf = [1]u8{0} ** std.fs.MAX_PATH_BYTES;
    const tmp_path = try std.os.getFdPath(tmp.dir.fd, &path_buf);
    // make tmp_path zero terminated
    path_buf[tmp_path.len] = 0;
    const tmp_path_zero_terminated = path_buf[0..tmp_path.len :0];

    std.debug.print("opening db {s}\n", .{tmp_path});
    var err: ?[*:0]u8 = null;
    const db = c.rocksdb_open(options, tmp_path_zero_terminated, &err);
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
