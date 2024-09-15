//! Logging module
const std = @import("std");

const Severity = enum {
    debug,
    // trace (verbose)
    info,
    warn,
    err,
    fatal,
};

fn isLeapYear(year: u64) bool {
    return if ((@mod(year, 4) == 0 and @mod(year, 100) != 0) or @mod(year, 400) == 0) true else false;
}

const Logger = struct {
    allocator: std.mem.Allocator,
    log_file: std.fs.File,

    /// Converts a unix epoch timestamp to a datetime in the form YYYY/MM/DD-HH:MM:SS
    pub fn timestampToDatetime(self: *const Logger, timestamp: i64) []const u8 {
        // const number_of_leap_seconds: comptime_int = 27;
        var current_year_unix: u32 = 1970;

        // const leap_timestamp: f80 = @as(f80, @as(f80, @floatFromInt(number_of_leap_seconds)) + @as(f80, @floatFromInt(timestamp)));
        const leap_timestamp: f80 = @as(f80, @floatFromInt(timestamp));

        const days_in_months: [12]i32 = [_]i32{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

        var extra_days: f80 = 0;

        // number of seconds that has passed from jan 1 1970
        // 27 leap seconds have passed since then
        var seconds_to_days: f80 = leap_timestamp / 86400;
        const extra_time: f80 = @mod(leap_timestamp, 86400);
        var flag: u8 = 0;

        while (true) {
            if (isLeapYear(current_year_unix)) {
                if (seconds_to_days < 366) {
                    break;
                }
                seconds_to_days -= 366;
            } else {
                if (seconds_to_days < 365) {
                    break;
                }
                seconds_to_days -= 365;
            }
            current_year_unix += 1;
        }

        extra_days = seconds_to_days + 1;

        if (isLeapYear(current_year_unix)) {
            flag = 1;
        }

        var date: f80 = 0;
        var month: u8 = 0;
        var index: u8 = 0;

        if (flag == 1) {
            while (true) {
                if (index == 1) {
                    if (extra_days - 29 < 0) {
                        break;
                    }

                    month += 1;
                    extra_days -= 29;
                } else {
                    if (extra_days - @as(f80, @floatFromInt(days_in_months[index])) < 0) {
                        break;
                    }

                    month += 1;
                    extra_days -= @as(f80, @floatFromInt(days_in_months[index]));
                }

                index += 1;
            }
        } else {
            while (true) {
                if (extra_days - @as(f80, @floatFromInt(days_in_months[index])) < 0) {
                    break;
                }

                month += 1;
                extra_days -= @as(f80, @floatFromInt(days_in_months[index]));
                index += 1;
            }
        }

        if (extra_days > 0) {
            month += 1;
            date = extra_days;
        } else {
            if (month == 2 and flag == 1) {
                date = 29;
            } else {
                date = @as(f80, @floatFromInt(days_in_months[month - 1]));
            }
        }

        // TODO: adjust for AEST time
        const hours = extra_time / 3600;
        const minutes = @divExact(@mod(extra_time, 3600), 60);
        const seconds = @mod(@mod(extra_time, 3600), 60);

        // YYYY/MM/DD-HH:MM:SS
        // In UTC time, because the current computer system is in UTC time, adjust for AEST
        const formatted_time: []u8 = std.fmt.allocPrint(self.allocator, "{d}/{d}/{d}-{d}:{d}:{d}", .{ current_year_unix, month, @floor(date), @floor(hours), minutes, seconds }) catch {
            // TODO: handle errors
            return undefined;
        };

        return formatted_time;
    }

    pub fn close(self: *const Logger) void {
        self.log_file.close();
    }

    // TODO: add struct arguments
    pub fn info(self: *Logger, namespace: []const u8, message: []const u8) !void {
        const current_time = std.time.timestamp();
        const formatted_time = self.timestampToDatetime(current_time);

        const combined = std.fmt.allocPrint(self.allocator, "INFO-{s}-{s}: {s}\n", .{ namespace, formatted_time, message }) catch {
            // return error, actually
            return;
        };

        _ = try self.log_file.write(combined);
    }

    pub fn warn(self: *Logger, namespace: []const u8, message: []const u8) !void {
        const current_time = std.time.timestamp();
        const formatted_time = self.timestampToDatetime(current_time);

        const combined = std.fmt.allocPrint(self.allocator, "WARNING-{s}-{s}: {s}\n", .{ namespace, formatted_time, message }) catch {
            // return error, actually
            return;
        };

        _ = try self.log_file.write(combined);
    }

    pub fn err(self: *Logger, namespace: []const u8, message: []const u8) !void {
        const current_time = std.time.timestamp();
        const formatted_time = self.timestampToDatetime(current_time);

        const combined = std.fmt.allocPrint(self.allocator, "ERROR-{s}-{s}: {s}\n", .{ namespace, formatted_time, message }) catch {
            return;
        };

        _ = try self.log_file.write(combined);
    }

    /// Will crash the program if called
    pub fn fatal(self: *Logger, namespace: []const u8, message: []const u8) !void {
        const current_time = std.time.timestamp();
        const formatted_time = self.timestampToDatetime(current_time);

        const combined = std.fmt.allocPrint(self.allocator, "ERROR-{s}-{s}: {s}\n", .{ namespace, formatted_time, message }) catch {
            return;
        };

        _ = try self.log_file.write(combined);

        std.posix.exit(1);
    }
};

pub var Log: Logger = Logger{
    .allocator = undefined,
    .log_file = undefined,
};

// more parameters such as defining where to open the file etc
/// Call once in the main function
pub fn initializeLogging(allocator: *std.mem.Allocator) !void {
    Log.allocator = allocator.*;
    Log.log_file = try std.fs.cwd().createFile("zigwm.log", .{ .read = true });
}

// How can we test this?
test "LogTest" {
    var gpa_allocator = std.testing.allocator_instance;
    const allocator = gpa_allocator.allocator();

    const TestLogger: Logger = Logger{
        .allocator = allocator,
        .log_file = try std.fs.cwd().createFile("testlogfile.log", .{ .read = true }),
    };
    defer TestLogger.close();

    // all shall be tested in UTC in 24 Hour Time
    // with the format YYYY/M,M/D,D-H,H:MM:SS
    const timestamp_1: u32 = 261325361;
    const datetime_1: []const u8 = TestLogger.timestampToDatetime(timestamp_1);
    try std.testing.expect(std.mem.eql(u8, datetime_1, "1978/4/13-14:22:41"));

    // create some custom timestamps, paste it into a unix epoch converter and check if the two strings match
    // contribute one every time u modify this file to make sure it works well
}
