pub const Patch = extern struct {
    width: i16,             // bounding box size 
    height: i16,
    leftoffset: i16,        // pixels to the left of origin
    topoffset: i16,         // pixels below the origin 
    columnoffs: [8]i32      // only [width] used
};

// Sprites are patches with a special naming convention
//  so they can be recognized by R_InitSprites.
// The base name is NNNNFx or NNNNFxFx, with
//  x indicating the rotation, x = 0, 1-7.
// The sprite and frame specified by a thing_t
//  is range checked at run time.
// A sprite is a patch_t that is assumed to represent
//  a three dimensional object and may have multiple
//  rotations pre drawn.
// Horizontal flipping is used to save space,
//  thus NNNNF2F5 defines a mirrored patch.
// Some sprites will only have one picture used
// for all views: NNNNF0
pub const SpriteFrame = struct {
    // If false use 0 for any position.
    // Note: as eight entries are available,
    //  we might as well insert the same name eight times.
    rotate: bool,

    // Lump to use for view angles 0-7.
    lump: [8]i16,

    // Flip bit (1 = flip) to use for view angles 0-7.
    flip: [8]u8
};

// A sprite definition:
//  a number of animation frames.
pub const SpriteDef = struct {
    numframes: i32,
    spriteframes: []SpriteFrame
};