const root = @import("root");
const game_state = root.game_state;
const Event = root.Event;

const menu_data = @import("menu_data.zig");

var menu_active: bool = false;
var currentMenu: *MenuScreen = undefined;
var is_menu_active = false;
var item_on: i16 = 0;

// skull animation things
var wich_skull: i16 = 0; // with skull to draw
var skull_frame: i16 = 0; // skull animation counter

var screen_size: i32 = undefined;
const screen_blocks: *i32 = &game_state.screenblocks;

var quick_save_slot: i32 = undefined;

pub const MenuScreen = struct {
    prevMenu: ?*MenuScreen,
    menuitens: []MenuItem,
    // draw routine
    x: i16,
    y: i16,
    lastOn: i16
};
pub const MenuItem = struct {
    status: i16,
    name: *const [10]u8,
    routine: *const fn (i32) void,
    hotkey: u8
};

pub fn init() !void {

    currentMenu = &menu_data.mainDef;
    is_menu_active = false;
    item_on = currentMenu.lastOn;

    wich_skull = 0;
    skull_frame = 10;

    screen_size = screen_blocks.* - 3;

    // messageToPrint = 0;
    // messageString = NULL;
    // messageLastMenuActive = menuactive;

    quick_save_slot = -1;

    switch (game_state.gamemode) {
        .commecial => {
            //  This is used because DOOM 2 had only one HELP
            //  page. I use CREDIT as second page now, but
	        //  kept this hack for educational purposes.
            menu_data.MainMenuOptions[4] = menu_data.MainMenuOptions[5];
            menu_data.mainDef.menuitens.len -= 1;
            menu_data.mainDef.y += 8;

            menu_data.newDef.prevMenu = &menu_data.mainDef;
            // ReadDef1.routine = M_DrawReadThis1;
            // ReadDef1.x = 330;
            // ReadDef1.y = 165;
            // ReadMenu1[0].routine = M_FinishReadThis;
        },

        .shareware,
        // Episode 2 and 3 are handled,
	    // branching to an ad screen.
        .registered => {
            // We need to remove the fourth episode.

            menu_data.epiDef.menuitens.len -= 1;
        },

        .retail => {
            // We are fine.
        },

        else => {}
    }

}

// game options
pub fn choise_NewGame(_: i32) void {}
pub fn choise_Settings(_: i32) void {}
pub fn choise_LoadGame(_: i32) void {}
pub fn choise_SaveGame(_: i32) void {}
pub fn choise_ReadThis(_: i32) void {}
pub fn choise_QuitGame(_: i32) void {}

pub fn choose_episode(episode: i32) void {
    _ = episode;
}
pub fn choose_skill(level: i32) void {
    _ = level;
}

pub fn event_responder(e: Event) bool {

    if (e != .keydown) return false;

    if (!menu_active) {
        if (e.keydown == .Esc) {

        }
    }

    return false;
    
}
