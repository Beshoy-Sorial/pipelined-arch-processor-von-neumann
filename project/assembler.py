class Assembler:
    def __init__(self, mem_size=2048):
        self.pc = 0
        self.mem = ["0" * 32 for _ in range(mem_size)]

        self.registers = {
            "R0": "000",
            "R1": "001",
            "R2": "010",
            "R3": "011",
            "R4": "100",
            "R5": "101",
            "R6": "110",
            "R7": "111",
        }

        self.opcodes = {
            "NOP": "0000000000",
            "HLT": "0000100000",
            "SETC": "0001000000",
            "NOT": "0001100100",
            "INC": "0010000100",
            "OUT": "0010100100",
            "IN": "0011000100",
            #####################
            "MOV": "0100000110",
            "SWAP": "0100100110",
            "ADD": "0101000111",
            "SUB": "0101100111",
            "AND": "0110000111",
            "IADD": "0110101110",
            ###################
            "PUSH": "1000000100",
            "POP": "1000100100",
            "LDM": "1001001100",
            "LDD": "1001110110",
            "STD": "1010010011",
            ########################
            "JZ": "1100001000",
            "JN": "1100101000",
            "JC": "1101001000",
            "JMP": "1101101000",
            "CALL": "1110001000",
            "RET": "1110100000",
            "INT": "1111001000",
            "RTI": "1111100000",
        }

    def clean(self, line):
        return line.split("#")[0].strip()

    def to_32bit(self, value):
        if value.startswith("0x"):
            num = int(value, 16)
        else:
            num = int(value)
        return f"{num & 0xFFFFFFFF:032b}"

    def write(self, word):
        self.mem[self.pc] = word
        self.pc += 1

    def assemble_line(self, line):
        line = self.clean(line)
        if not line:
            return

        if line.startswith(".ORG"):
            self.pc = int(line.split()[1])
            return

        parts = line.replace(",", " ").replace("(", " ").replace(")", "").split()
        instr = parts[0].upper()
        opcode = self.opcodes[instr]

        # ---------- ZERO OPERAND ----------
        if instr in ["NOP", "HLT", "SETC", "RET", "RTI"]:
            self.write(opcode + "0" * 22)
            return

        # ---------- ONE OPERAND ----------
        if instr in ["NOT", "INC", "OUT", "IN", "PUSH", "POP"]:
            r = self.registers[parts[1]]
            self.write(opcode + r + r + "0" * 16)
            return

        # ---------- MOV ----------
        if instr == "MOV":
            rsrc = self.registers[parts[1]]
            rdst = self.registers[parts[2]]
            self.write(opcode + rdst + rsrc + "0" * 16)
            return

        # ---------- SWAP ----------
        if instr == "SWAP":
            r1 = self.registers[parts[1]]
            r2 = self.registers[parts[2]]
            self.write(opcode + "000" + r1 + r2 + "0" * 13)
            return

        # ---------- THREE REG ALU ----------
        if instr in ["ADD", "SUB", "AND"]:
            rdst = self.registers[parts[1]]
            r1 = self.registers[parts[2]]
            r2 = self.registers[parts[3]]
            self.write(opcode + rdst + r1 + r2 + "0" * 13)
            return

        # ---------- IADD ----------
        if instr == "IADD":
            rdst = self.registers[parts[1]]
            rsrc = self.registers[parts[2]]
            self.write(opcode + rdst + rsrc + "000" + "0" * 13)
            self.write(self.to_32bit(parts[3]))
            return

        # ---------- MEMORY ----------
        # if instr == "PUSH":
        #     r = self.registers[parts[1]]
        #     self.write(opcode + r + "0" * 19)
        #     return

        # if instr == "POP":
        #     r = self.registers[parts[1]]
        #     self.write(opcode + r + "0" * 19)
        #     return

        if instr == "LDM":
            rdst = self.registers[parts[1]]
            self.write(opcode + rdst + "0" * 19)
            self.write(self.to_32bit(parts[2]))
            return

        if instr == "LDD":
            rdst = self.registers[parts[1]]
            rsrc = self.registers[parts[3]]
            self.write(opcode + rdst + rsrc + "0" * 16)
            self.write(self.to_32bit(parts[2]))
            return

        if instr == "STD":
            rsrc1 = self.registers[parts[1]]
            rsrc2 = self.registers[parts[3]]
            self.write(opcode + "000" + rsrc1 + rsrc2 + "0" * 13)
            self.write(self.to_32bit(parts[2]))
            return

        # ---------- BRANCH / CALL ----------
        if instr in ["JZ", "JN", "JC", "JMP", "CALL"]:
            self.write(opcode + "0" * 22)
            self.write(self.to_32bit(parts[1]))
            return

        # ---------- INT ----------
        if instr == "INT":
            index = parts[1]
            self.write(opcode + "0" * 21 + index)
            return

        raise Exception(f"Unknown instruction: {line}")

    # --------------------------------------------------

    def assemble(self, input_file):
        with open(input_file) as file:
            for line in file:
                self.assemble_line(line)

    def write_txt(self, out_file):
        with open(out_file, "w") as file:
            for w in self.mem:
                file.write(w + "\n")

    def write_mif(self, out_file):
        with open(out_file, "w") as f:
            f.write(f"WIDTH=32;\n")
            f.write(f"DEPTH={len(self.mem)};\n")
            f.write("ADDRESS_RADIX=UNS;\n")
            f.write("DATA_RADIX=BIN;\n")
            f.write("CONTENT BEGIN\n")
            for addr, word in enumerate(self.mem):
                f.write(f"  {addr} : {word};\n")
            f.write("END;\n")


def main():
    asm = Assembler(mem_size=1024)
    asm.assemble("program.txt")
    asm.write_txt("memory.txt")
    asm.write_mif("memory.mif")


if __name__ == "__main__":
    main()


# 32 bits contains 10 bits for opcode then 3 bits rdst then 3 bits rsrc1 then 3 bits rsrc2 then zeros  in all except in int 0 or int 1  last digit must be 0 or 1


# 2 BITS -> 2 bits for instruction type
# 3 BITS ->3 bits for operation
# 1 BIT -> 1 bit for offset
# 1 BIT -> 1 bit for immediate
# 3 BITS -> 3 bits for the usage of Rdest,Rsrc1,Rsrc2
# One Operand :
# NOP -> 0000000000 (rest zeros)
# HLT -> 0000100000 (rest zeros)
# SETC -> 0001000000 (rest zeros)
# NOT Rdst -> 0001100100 rdst rdst (rest zeros)
# INC Rdst -> 0010000100 rdst rdst (rest zeros)
# OUT Rdst -> 0010100100 rdst rdst (rest zeros)
# IN Rdst -> 0011000100 rdst rdst (rest zeros)

# Two Operands :
# MOV Rsrc, Rdst -> 0100000110 rdst rsrc1 (rest zeros)
# SWAP Rsrc1,Rsrc2 -> 0100100110 000 rsrc1 rsrc2 (rest zeros)
# ADD Rdst,Rsrc1, Rsrc2 -> 0101000111 rdst rsrc1 rsrc2 (rest zeros)
# SUB Rdst,Rsrc1, Rsrc2 -> 0101100111 rdst rsrc1 rsrc2 (rest zeros)
# AND Rdst,Rsrc1, Rsrc2 -> 0110000111 rdst rsrc1 rsrc2 (rest zeros)
# IADD Rdest, Rsrc1,IMM -> 0110101110 rdst rsrc1 rsrc2 (rest zeros)
#                       -> immediate on the next line


# Memory Operations :
# PUSH Rdst ->1000000100 rdst rdst (rest zeros)
# POP Rdst ->1000100100 rdst rdst (rest zeros)
# LDM Rdst, Imm ->1001001100 rdst (rest zeros)
#               ->immediate on the next line
# LDD Rdst,offset(Rsrc1)->1001110110 rdst rsrc1 (rest zeros)
#                       ->immediate on the next line
# STD Rsrc1,offset(Rsrc2)->1010010011 000 rsrc1 rsrc2 (rest zeros)
#                        ->immediate on the next line


# Branch and Change of Control Operations:
# JZ IMM ->1100001000 (rest zeros)
#                        ->immediate on the next line
# JN IMM ->1100101000 (rest zeros)
#                        ->immediate on the next line
# JC IMM ->1101001000 (rest zeros)
#                        ->immediate on the next line
# JMP IMM ->1101101000 (rest zeros)
#                        ->immediate on the next line
# CALL IMM ->1110001000 (rest zeros)
#                        ->immediate on the next line
# RET ->1110100000 (rest zeros)
# INT index ->1111001000 (rest zeros) except last digit is zero or 1 due to int 0 or 1
# RTI ->1111100000
