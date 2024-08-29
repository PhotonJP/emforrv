const std = @import("std");

const Instruction = union(enum) {
    instAddi: struct { rd: u5, rs1: u5, imm: i12 },
    instHlt: void,
};

const reg_x0 = 0;
const reg_x1 = 1;

pub fn main() !void {
    var memory: [1024]u8 = undefined;
    assemble(&memory);

    var pc: u32 = 0;
    var ir: u32 = 0;
    var reg: [4]u32 = .{ 0, 0, 0, 0 };

    while (true) : (pc += 4) {
        ir = fetch(pc, &memory);
        std.debug.print("pc:{x:08}  ir:{x:08}\n", .{ pc, ir });

        const inst = decode(ir);
        switch (inst) {
            .instAddi => |v| {
                reg[v.rd] = reg[v.rs1] +% @as(u32, @bitCast(@as(i32, v.imm)));
                std.debug.print("addi rd:{d} rs:{d} imm:{d} => {d}\n", .{ v.rd, v.rs1, v.imm, reg[v.rd] });
            },
            else => {
                break;
            },
        }
    }
}

fn fetch(pc: u32, rom: []const u8) u32 {
    return @as(u32, rom[pc + 3]) << 24 | @as(u32, rom[pc + 2]) << 16 | @as(u32, rom[pc + 1]) << 8 | @as(u32, rom[pc]);
}

fn decode(ir: u32) Instruction {
    const opcode = ir & 0x0000007F;
    return switch (opcode) {
        0b0010011 => Instruction{ .instAddi = .{
            .rd = @truncate(ir >> 7),
            .rs1 = @truncate(ir >> 15),
            .imm = @truncate(@as(i64, ir >> 20)),
        } },
        else => Instruction{ .instHlt = {} },
    };
}

fn assemble(memory: []u8) void {
    const inst0 = assembleAddi(reg_x1, reg_x0, -2048);
    memory[0] = @truncate(inst0);
    memory[1] = @truncate(inst0 >> 8);
    memory[2] = @truncate(inst0 >> 16);
    memory[3] = @truncate(inst0 >> 24);

    const inst1 = assembleAddi(reg_x1, reg_x1, 2047);
    memory[4] = @truncate(inst1);
    memory[5] = @truncate(inst1 >> 8);
    memory[6] = @truncate(inst1 >> 16);
    memory[7] = @truncate(inst1 >> 24);
}

fn assembleAddi(rd: u5, rs1: u5, imm: i12) u32 {
    return @as(u32, @bitCast(@as(i32, imm))) << 20 | @as(u32, rs1) << 15 | 0b000 << 12 | @as(u32, rd) << 7 | 0b0010011;
}
