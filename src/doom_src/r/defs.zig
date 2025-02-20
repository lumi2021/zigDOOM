pub const Patch = extern struct {
    width: i16,             // bounding box size 
    height: i16,
    leftoffset: i16,        // pixels to the left of origin
    topoffset: i16,         // pixels below the origin 
    columnoffs: [8]i32      // only [width] used
};