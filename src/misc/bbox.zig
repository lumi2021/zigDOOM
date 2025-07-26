const std = @import("std");

const box_top = 0;
const box_bottom = 1;
const box_left = 2;
const box_right = 3;


pub fn clear_box(box: *[4]isize) void {
    box[box_top] = std.math.minInt(isize);
    box[box_bottom] = std.math.minInt(isize);

    box[box_left] = std.math.maxInt(isize);
    box[box_right] = std.math.maxInt(isize);
}

pub fn add_to_box(box: *[4]isize, x: isize, y: isize) void {
    if (x < box[box_left]) box[box_left] = x
    else if (x > box[box_right]) box[box_right] = x;

    if (y < box[box_bottom]) box[box_bottom] = y
    else if (y > box[box_top]) box[box_top] = y;
}
