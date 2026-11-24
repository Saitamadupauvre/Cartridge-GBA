const std = @import("std");

pub const nintendo_logo_reference = [156]u8{
    0x24, 0xff, 0xae, 0x51, 0x69, 0x9a, 0xa2, 0x21, 0x3d, 0x84, 0x82, 0x0a,
    0x84, 0xe4, 0x09, 0xad, 0x11, 0x24, 0x8b, 0x98, 0xc0, 0x81, 0x7f, 0x21,
    0xa3, 0x52, 0xbe, 0x19, 0x93, 0x09, 0xce, 0x20, 0x10, 0x46, 0x4a, 0x4a,
    0xf8, 0x27, 0x31, 0xec, 0x58, 0xc7, 0xe8, 0x33, 0x82, 0xe3, 0xce, 0xbf,
    0x85, 0xf4, 0xdf, 0x94, 0xce, 0x4b, 0x09, 0xc1, 0x94, 0x56, 0x8a, 0xc0,
    0x13, 0x72, 0xa7, 0xfc, 0x9f, 0x84, 0x4d, 0x73, 0xa3, 0xca, 0x9a, 0x61,
    0x58, 0x97, 0xa3, 0x27, 0xfc, 0x03, 0x98, 0x76, 0x23, 0x1d, 0xc7, 0x61,
    0x03, 0x04, 0xae, 0x56, 0xbf, 0x38, 0x84, 0x00, 0x40, 0xa7, 0x0e, 0xfd,
    0xff, 0x52, 0xfe, 0x03, 0x6f, 0x95, 0x30, 0xf1, 0x97, 0xfb, 0xc0, 0x85,
    0x60, 0xd6, 0x80, 0x25, 0xa9, 0x63, 0xbe, 0x03, 0x01, 0x4e, 0x38, 0xe2,
    0xf9, 0xa2, 0x34, 0xff, 0xbb, 0x3e, 0x03, 0x44, 0x78, 0x00, 0x90, 0xcb,
    0x88, 0x11, 0x3a, 0x94, 0x65, 0xc0, 0x7c, 0x63, 0x87, 0xf0, 0x3c, 0xaf,
    0xd6, 0x25, 0xe4, 0x8b, 0x38, 0x0a, 0xac, 0x72, 0x21, 0xd4, 0xf8, 0x07,
};

pub const BranchOpcode = struct {
    offset: i32,
    target: u32,
};

pub const Header = extern struct {
    entry_point: [4]u8,
    nintendo_logo: [156]u8,
    game_title: [12]u8,
    game_code: [4]u8,
    maker_code: [2]u8,
    fixed_value: u8,
    main_unit_code: u8,
    device_type: u8,
    reserved: [7]u8,
    software_version: u8,
    complement_check: u8,
    checksum_reserved: [2]u8,

    pub fn fromByte(buffer: *const [192]u8) *const Header {
        return @ptrCast(buffer);
    }

    pub fn parse(buffer: *const [192]u8) Header {
        return fromByte(buffer).*;
    }

    pub fn entryRaw(self: *const Header) u32 {
        return std.mem.readInt(u32, &self.entry_point, .little);
    }

    pub fn entryValid(self: *const Header) bool {
        return (self.entryRaw() >> 24) == 0xea;
    }

    pub fn entryOpcode(self: *const Header) ?BranchOpcode {
        if (!self.entryValid()) return null;

        const raw = self.entryRaw();
        const offset: i32 = @as(i32, @bitCast(raw << 8)) >> 8;
        const target: u32 = @bitCast(8 + offset * 4);
        return .{ .offset = offset, .target = target };
    }

    pub fn logoValid(self: *const Header) bool {
        return std.mem.eql(u8, &self.nintendo_logo, &nintendo_logo_reference);
    }

    pub fn reservedValid(self: *const Header) bool {
        return std.mem.allEqual(u8, &self.reserved, 0);
    }

    pub fn fixedValueValid(self: *const Header) bool {
        return self.fixed_value == 0x96;
    }

    pub fn makerName(self: *const Header) []const u8 {
        if (std.mem.eql(u8, &self.maker_code, "01")) return "Nintendo";
        return "Unknown";
    }

    pub fn gameRegion(self: *const Header) []const u8 {
        return switch (self.game_code[3]) {
            'J' => "Japan",
            'E' => "USA/English",
            'P' => "Europe",
            'D' => "Germany",
            'F' => "France",
            'I' => "Italy",
            'S' => "Spain",
            else => "Unknown",
        };
    }

    pub fn computeChecksum(buffer: *const [192]u8) u8 {
        var checksum: u8 = 0;
        for (buffer[0xa0..0xbc]) |byte| checksum -%= byte;
        checksum -%= 0x19;
        return checksum;
    }

    pub fn checksumValid(self: *const Header, buffer: *const [192]u8) bool {
        return self.complement_check == computeChecksum(buffer);
    }
};
