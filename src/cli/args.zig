const clap = @import("clap");

pub const MainCommand = enum { hdr, build, emu };
pub const HdrCommand = enum { dump, gen };

pub const main_parsers = .{
    .command = clap.parsers.enumeration(MainCommand),
};
pub const main_params = clap.parseParamsComptime(
    \\-h, --help  Display this help and exit.
    \\<command>
    \\
);

pub const build_params = clap.parseParamsComptime(
    \\-h, --help  Display this help and exit.
    \\
);

pub const emu_params = clap.parseParamsComptime(
    \\-h, --help  Display this help and exit.
    \\
);

pub const hdr_parsers = .{
    .command = clap.parsers.enumeration(HdrCommand),
};
pub const hdr_params = clap.parseParamsComptime(
    \\-h, --help  Display this help and exit.
    \\<command>
    \\
);

pub const dump_params = clap.parseParamsComptime(
    \\-h, --help  Display this help and exit.
    \\<str>...
    \\
);

pub const gen_params = clap.parseParamsComptime(
    \\-h, --help         Display this help and exit.
    \\-b, --binary <str>     Path to the binary.
    \\-o, --output <str>     Path to write the header to.
    \\-n, --name <str>       Name of the generated header.
    \\
);

pub const DumpOptions = struct {
    help: bool = false,
};

pub const GenOptions = struct {
    help: bool = false,
    binary: ?[]const u8 = null,
    output: ?[]const u8 = null,
    name: ?[]const u8 = null,
};
