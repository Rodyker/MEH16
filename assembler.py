text = []
out = []

with open('program.s') as f:
    for line in f:
        text.append(line.split())

funcs = {
    "LDW": "0001",
    "STW": "0010",
    "ADD": "0011",
    "ADC": "0100",
    "SUB": "0101",
    "SBB": "0110",
    "MOD": "0111",
    "AND": "1000",
    "OR": "1001",
    "XOR": "1010",
    "JMP": "1011",
    "JPZ": "1100",
    "JPC": "1101",
    "JPS": "1110",
    "CAL": "1111",
    "MSW": "0000001",
    "POP": "0000010",
    "RET": "0000011",
    "BWS": "000000000001",
    "BWC": "000000000010",
    "BWJ": "000000000011",
    "BOS": "000000000100",
    "BOC": "000000000101",
    "BIJ": "000000000110",
    "BSL": "000000000111",
    "NOP": "0000000000000000",
    "INC": "0000000000000001",
    "DEC": "0000000000000010",
    "RTL": "0000000000000011",
    "RTR": "0000000000000100",
    "NOT": "0000000000000101",
    "COM": "0000000000000110",
    "LDP": "0000000000000111",
    "STP": "0000000000001000",
    "MWO": "0000000000001001",
    "MIW": "0000000000001010",
    "CLW": "0000000000001011",
    "CLO": "0000000000001100",
    "PSH": "0000000000001110",
    "RST": "0000000000001111"
}

labels = {}
line_num = -1
for line in text:
    if len(line) != 0:
        if ":" in line[0]:
            labels[line[0][:-1]] = line_num + 1
        else:
            line_num += 1


for line in text:
    out_word = ""
    if len(line) != 0:
        op = funcs.get(line[0])
        if ":" not in line[0]:
            if op is not None:
                out_word += op
                if len(op) != 16:
                    if labels.get(line[1]) is not None:
                        out_word += bin(labels.get(line[1]))[2:].zfill(16 - len(op))
                    else:
                        out_word += bin(int(line[1], 16))[2:].zfill(16 - len(op))
            else:
                out_word += bin(int(line[0], 16))[2:].zfill(16)
            out.append(out_word)
        
    
    
#write out to file
with open('program.bin', 'w') as f:
    for item in out:
        f.write("%s\n" % item)