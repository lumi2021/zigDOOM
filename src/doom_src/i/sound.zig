const std = @import("std");
const root = @import("root");
const src = root.doom_src;

const s = src.s;

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/i_sound.c#L738
pub fn init_sound() void {
    // bruh wtf i will do here
    std.debug.print("\nTODO implement sound\n\n", .{});
    // TODO sound system
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/i_sound.c#L396
pub fn set_channels() void {
    // FIXME this function does not on linux, only in DOS and this
    // version is not planned for DOS.
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/i_sound.c#L438
// MUSIC API - dummy. Some code from DOS version.
pub fn set_music_volume(volume: i32) void {
  // Internal state variable.
  s.sound.snd_MusicVolume = volume;
  // Now set volume on output device.
  // Whatever( snd_MusciVolume );
}
