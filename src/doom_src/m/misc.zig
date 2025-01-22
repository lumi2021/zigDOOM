// implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/m_misc.c#L340
const std = @import("std");
const root = @import("root");

const alloc = root.allocator;

const Default = struct {
    name: []const u8,
    location: *i32,
    defaultValue: i32,
    scantranslate: i32 = 0, // pc scancode hack
    untranslated: i32  = 0,  // lousy hack
};

// settings (or defaults)
var mouseSensitivity: i32 = undefined;

var sound_sfxVolume: i32 = undefined;
var sound_musicVolume: i32 = undefined;

var showMessages: i32 = undefined;

var numdefaults: i32 = undefined;

const defaults: [4]Default = .{
    Default{
        .name = "mouse_sensitivity",
        .location = &mouseSensitivity, 
        .defaultValue = 5,
    },
    .{
        .name = "sfx_volume",
        .location = &sound_sfxVolume, 
        .defaultValue = 8,
    },
    .{
        .name = "music_volume",
        .location = &sound_musicVolume, 
        .defaultValue = 8,
    },
    .{
        .name = "show_messages",
        .location = &showMessages, 
        .defaultValue = 1,
    },

    // TODO more settings
};

var defaultfile: []const u8 = undefined;
const basedefault: []const u8 = "default.cfg";

pub fn load_defaults() !void {

    // set everything to base values
    numdefaults = defaults.len;
    for (defaults) |default| {
        default.location.* = default.defaultValue;
    }

    // check for a custom default file
    // TODO-config flag
    defaultfile = basedefault;

    const p: ?[]u8 = std.fs.realpathAlloc(alloc.*, defaultfile) catch null;
    
    if (p) |path| {
        const handle = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
        const reader = handle.reader();

        // process the config file here
        // https://github.com/id-Software/DOOM/blob/a77dfb96cb91780ca334d0d4cfd86957558007e0/linuxdoom-1.10/m_misc.c#L370
        while (true) {
            std.debug.print("\"{0c}\" {0X:0>2} ", .{reader.readByte() catch break});
        }
        std.debug.print("\n", .{});

        handle.close();
    }
    else std.debug.print("Default file not found!\n", .{});
}

pub fn save_defualts() !void {
    
}
