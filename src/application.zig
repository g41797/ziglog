//---------------------------------
const std           = @import("std");
const mem           = std.mem;
const testing       = std.testing;
const string        = @import("shortstring.zig");
const pid        	= @import("pid.zig");
const ShortString   = string.ShortString;
const builtin       = @import("builtin");
const native_os     = builtin.os.tag;
const rfc5424   	= @import("rfc5424.zig");
//---------------------------------

// HOSTNAME        = NILVALUE / 1*255PRINTUSASCII
// APP-NAME        = NILVALUE / 1*48PRINTUSASCII

pub const MAX_HOST_NAME: u8 = 255;
pub const MAX_APP_NAME: u8  = 48;

const AppName   = ShortString(MAX_APP_NAME);
const HostName  = ShortString(MAX_HOST_NAME);

pub const Application = struct {

    const Self = @This();

    app_name:   AppName,
    host_name:  HostName,
    procid:     pid.ProcID,
    fcl:        rfc5424.Facility    = undefined,


    pub fn init(app: *Application, name: []const u8, fcl: rfc5424.Facility) !void {

        _ = try app.*.app_name.fillFrom(name);

        _ = try pid.storePID(&app.*.procid);

        _ = try app.setHostName();

        app.*.fcl = fcl;

        return;
    }

    fn setHostName(appl: *Application) !void {

        const envMame =     switch (native_os) {
            .windows    => "COMPUTERNAME",
            .linux      => "HOSTNAME",
            else        => unreachable,
        };

        var buffer: [MAX_HOST_NAME]u8 = undefined;

        var   fbAllocator   = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator     = fbAllocator.allocator();
        const hostName      = try std.process.getEnvVarOwned(allocator, envMame);

        defer allocator.free(hostName);

        _ = try appl.*.host_name.fillFrom(hostName);

        return;
    }

};


test "application init" {
    var logger: Application = undefined;

    _ = try logger.init("logger", rfc5424.Facility.local0);
}
