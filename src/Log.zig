//! Logging module
const std = @import("std");

const number_of_leap_seconds: comptime_int = 27;
const seconds_in_year: comptime_int = 31557600;

const Severity = enum {
    debug,
    // trace (verbose)
    info,
    warn,
    err,
    fatal,
};

const Logger = struct {
    allocator: std.mem.Allocator,
    log_file: std.fs.File,

    pub fn timestampToDatetime(timestamp: i64, allocator: std.mem.Allocator) []const u8 {
        const leap_timestamp: f80 = @as(f80, @as(f80, @floatFromInt(number_of_leap_seconds)) + @as(f80, @floatFromInt(timestamp)));
        std.debug.print("leap_timestamp: {d}\n", .{leap_timestamp});

        // leap timestamp is 1726277658
        // number of seconds in a year is 31557600
        // number of leap seconds is 27

        // number of seconds that has passed from jan 1 1970
        // 27 leap seconds have passed since then

        const year: f80 = 1970 + (leap_timestamp / @as(f80, @floatFromInt(seconds_in_year)));
        const month: f80 = @mod(year, 1) * @as(f80, @floatFromInt(12));

        var is_leap_year: bool = false;
        var days_in_months: [12]i32 = [_]i32{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
        if ((@mod(std.math.floor(year), 4) == 0) and (@mod(std.math.floor(year), 100) != 0)) {
            days_in_months[1] = 29;
            is_leap_year = true;
        } else if (@mod(std.math.floor(year), 400) == 0) {
            days_in_months[1] = 29;
            is_leap_year = true;
        }

        var day: f80 = 0;
        for (days_in_months, 0..) |current_month, index| {
            if (@as(i32, @intFromFloat(std.math.floor(month))) == index) {
                day = @as(f80, @floatFromInt(current_month)) * @mod(month, 1);

                if (is_leap_year) day += 1;
            }
        }

        // !!! now to do this !!!
        const hour: f80 = ((leap_timestamp / 86400) - @floor(leap_timestamp / 86400)) * 12;
        const minute: f80 = (hour - @floor(hour)) * 60;
        const second: f80 = (minute - @floor(minute)) * 60;

        // YYYY/MM/DD
        // month is ceiled because we say we are in the 9th month (sept) even though we are not complete with the month, same with day
        // this is odd because we say we are in 2024 even though 2024 is not complete, and technically we are in the 2025th year of the calendar
        const formatted_time: []u8 = std.fmt.allocPrint(allocator, "{d}/{d}/{d}-{d}:{d}:{d}", .{ @floor(year), @ceil(month), @ceil(day), @floor(hour), @floor(minute), @floor(second) }) catch {
            // TODO: handle errors
            return undefined;
        };

        return formatted_time;
    }

    pub fn close(self: *Logger) void {
        self.log_file.close();
    }

    pub fn info(self: *Logger, namespace: []const u8, message: []const u8) !void {
        const current_time = std.time.timestamp();
        const formatted_time = timestampToDatetime(current_time, self.allocator);

        const combined = std.fmt.allocPrint(self.allocator, "INFO-{s}-{s}: {s}", .{ namespace, formatted_time, message }) catch {
            // return error, actually
            return;
        };

        _ = try self.log_file.write(combined);
    }
};

pub var Log: Logger = Logger{
    .allocator = undefined,
    .log_file = undefined,
};

// more parameters such as defining where to open the file etc
pub fn initializeLogging(allocator: *std.mem.Allocator) !void {
    Log.allocator = allocator.*;
    Log.log_file = try std.fs.cwd().createFile("zigwm.log", .{ .read = true });
}

// How can we test this?
test "Time" {
    // create some custom timestamps, paste it into a unix epoch converter and check if the two strings match
    // contribute one every time u modify this file to make sure it works well
}
