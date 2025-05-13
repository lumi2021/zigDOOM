const std = @import("std");
const root = @import("root");
const src = root.doom_src;

const i = src.i;

// These are not used, but should be (menu).
// Maximum volume of a sound effect.
// Internal default is max out of 0-15.
pub var snd_SfxVolume: i32 = 15;

pub var snd_MusicVolume: i32 = 15;


const SfxInfo = struct {
    // up to 6-character name
    name: []const u8,

    // Sfx singularity (only one at a time)
    singularity: i32,

    // Sfx priority
    priority: i32,

    // referenced sound if a link
    link: ?*SfxInfo,

    // pitch if a link
    pitch: i32,

    // volume if a link
    volume: i32,

    // sound data
    data: *anyopaque,

    // this is checked every second to see if sound
    // can be thrown out (if 0, then decrement, if -1,
    // then throw out, if > 0, then it is in use)
    usefulness: i32,

    // lump number of sfx
    lumpnum: i32,
};
const Channel = struct {
    // sound information (if null, channel avail.)
    sfxinfo: ?*SfxInfo,

    // origin of sound
    origin: *anyopaque,

    // handle of the sound being played
    handle: i32
};


// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/s_sound.c#L161
pub fn init(sfxVolume: i32, musicVolume:i32) void {

    root.print_err("S_Init: default sfx volume %d\n", .{sfxVolume});

    // Whatever these did with DMX, these are rather dummies now.
    i.sound.set_channels();

    set_sfx_volume(sfxVolume);
    // No music with Linux - another dummy.
    set_music_volume(musicVolume);

    // Allocating the internal channels for mixing
    // (the maximum numer of sounds rendered
    // simultaneously) within zone memory.


}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/s_sound.c#L631
pub fn set_sfx_volume(volume: i32) void {
    if (volume < 0 or volume > 127) std.debug.panic("Attempt to set sfx volume at {}", .{volume});

    snd_SfxVolume = volume;
}

// Implementation of:
//     https://github.com/id-Software/DOOM/blob/master/linuxdoom-1.10/s_sound.c#L616
pub fn set_music_volume(volume: i32) void {
    if (volume < 0 or volume > 127) std.debug.panic("Attempt to set music volume at {}", .{volume});

    i.sound.set_music_volume(127);
    i.sound.set_music_volume(volume);
    snd_MusicVolume = volume;
}
