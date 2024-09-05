/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Chips & Scripts (rmetchev@ieee.org) 
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2024 Brilliant Labs Limited
 */
 
 module gamma_correction (
    input logic clock_in,
    input logic reset_n_in,

    input logic [7:0] red_data_in,
    input logic [7:0] green_data_in,
    input logic [7:0] blue_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [7:0] red_data_out,
    output logic [7:0] green_data_out,
    output logic [7:0] blue_data_out,
    output logic line_valid_out,
    output logic frame_valid_out
);

logic [7:0] gamma_rom_r [255:0];
logic [7:0] gamma_rom_g [255:0];
logic [7:0] gamma_rom_b [255:0];

initial begin
    gamma_rom_r[0]   = 'd0;   gamma_rom_g[0]   = 'd0;   gamma_rom_b[0]   = 'd0;
    gamma_rom_r[1]   = 'd4;   gamma_rom_g[1]   = 'd4;   gamma_rom_b[1]   = 'd4;
    gamma_rom_r[2]   = 'd9;   gamma_rom_g[2]   = 'd9;   gamma_rom_b[2]   = 'd9;
    gamma_rom_r[3]   = 'd13;  gamma_rom_g[3]   = 'd13;  gamma_rom_b[3]   = 'd13;
    gamma_rom_r[4]   = 'd18;  gamma_rom_g[4]   = 'd18;  gamma_rom_b[4]   = 'd18;
    gamma_rom_r[5]   = 'd22;  gamma_rom_g[5]   = 'd22;  gamma_rom_b[5]   = 'd22;
    gamma_rom_r[6]   = 'd26;  gamma_rom_g[6]   = 'd26;  gamma_rom_b[6]   = 'd26;
    gamma_rom_r[7]   = 'd30;  gamma_rom_g[7]   = 'd30;  gamma_rom_b[7]   = 'd30;
    gamma_rom_r[8]   = 'd33;  gamma_rom_g[8]   = 'd33;  gamma_rom_b[8]   = 'd33;
    gamma_rom_r[9]   = 'd36;  gamma_rom_g[9]   = 'd36;  gamma_rom_b[9]   = 'd36;
    gamma_rom_r[10]  = 'd40;  gamma_rom_g[10]  = 'd40;  gamma_rom_b[10]  = 'd40;
    gamma_rom_r[11]  = 'd42;  gamma_rom_g[11]  = 'd42;  gamma_rom_b[11]  = 'd42;
    gamma_rom_r[12]  = 'd45;  gamma_rom_g[12]  = 'd45;  gamma_rom_b[12]  = 'd45;
    gamma_rom_r[13]  = 'd48;  gamma_rom_g[13]  = 'd48;  gamma_rom_b[13]  = 'd48;
    gamma_rom_r[14]  = 'd50;  gamma_rom_g[14]  = 'd50;  gamma_rom_b[14]  = 'd50;
    gamma_rom_r[15]  = 'd53;  gamma_rom_g[15]  = 'd53;  gamma_rom_b[15]  = 'd53;
    gamma_rom_r[16]  = 'd55;  gamma_rom_g[16]  = 'd55;  gamma_rom_b[16]  = 'd55;
    gamma_rom_r[17]  = 'd57;  gamma_rom_g[17]  = 'd57;  gamma_rom_b[17]  = 'd57;
    gamma_rom_r[18]  = 'd59;  gamma_rom_g[18]  = 'd59;  gamma_rom_b[18]  = 'd59;
    gamma_rom_r[19]  = 'd61;  gamma_rom_g[19]  = 'd61;  gamma_rom_b[19]  = 'd61;
    gamma_rom_r[20]  = 'd63;  gamma_rom_g[20]  = 'd63;  gamma_rom_b[20]  = 'd63;
    gamma_rom_r[21]  = 'd65;  gamma_rom_g[21]  = 'd65;  gamma_rom_b[21]  = 'd65;
    gamma_rom_r[22]  = 'd67;  gamma_rom_g[22]  = 'd67;  gamma_rom_b[22]  = 'd67;
    gamma_rom_r[23]  = 'd69;  gamma_rom_g[23]  = 'd69;  gamma_rom_b[23]  = 'd69;
    gamma_rom_r[24]  = 'd71;  gamma_rom_g[24]  = 'd71;  gamma_rom_b[24]  = 'd71;
    gamma_rom_r[25]  = 'd73;  gamma_rom_g[25]  = 'd73;  gamma_rom_b[25]  = 'd73;
    gamma_rom_r[26]  = 'd75;  gamma_rom_g[26]  = 'd75;  gamma_rom_b[26]  = 'd75;
    gamma_rom_r[27]  = 'd76;  gamma_rom_g[27]  = 'd76;  gamma_rom_b[27]  = 'd76;
    gamma_rom_r[28]  = 'd78;  gamma_rom_g[28]  = 'd78;  gamma_rom_b[28]  = 'd78;
    gamma_rom_r[29]  = 'd80;  gamma_rom_g[29]  = 'd80;  gamma_rom_b[29]  = 'd80;
    gamma_rom_r[30]  = 'd81;  gamma_rom_g[30]  = 'd81;  gamma_rom_b[30]  = 'd81;
    gamma_rom_r[31]  = 'd83;  gamma_rom_g[31]  = 'd83;  gamma_rom_b[31]  = 'd83;
    gamma_rom_r[32]  = 'd84;  gamma_rom_g[32]  = 'd84;  gamma_rom_b[32]  = 'd84;
    gamma_rom_r[33]  = 'd86;  gamma_rom_g[33]  = 'd86;  gamma_rom_b[33]  = 'd86;
    gamma_rom_r[34]  = 'd87;  gamma_rom_g[34]  = 'd87;  gamma_rom_b[34]  = 'd87;
    gamma_rom_r[35]  = 'd89;  gamma_rom_g[35]  = 'd89;  gamma_rom_b[35]  = 'd89;
    gamma_rom_r[36]  = 'd90;  gamma_rom_g[36]  = 'd90;  gamma_rom_b[36]  = 'd90;
    gamma_rom_r[37]  = 'd92;  gamma_rom_g[37]  = 'd92;  gamma_rom_b[37]  = 'd92;
    gamma_rom_r[38]  = 'd93;  gamma_rom_g[38]  = 'd93;  gamma_rom_b[38]  = 'd93;
    gamma_rom_r[39]  = 'd95;  gamma_rom_g[39]  = 'd95;  gamma_rom_b[39]  = 'd95;
    gamma_rom_r[40]  = 'd96;  gamma_rom_g[40]  = 'd96;  gamma_rom_b[40]  = 'd96;
    gamma_rom_r[41]  = 'd97;  gamma_rom_g[41]  = 'd97;  gamma_rom_b[41]  = 'd97;
    gamma_rom_r[42]  = 'd99;  gamma_rom_g[42]  = 'd99;  gamma_rom_b[42]  = 'd99;
    gamma_rom_r[43]  = 'd100; gamma_rom_g[43]  = 'd100; gamma_rom_b[43]  = 'd100;
    gamma_rom_r[44]  = 'd101; gamma_rom_g[44]  = 'd101; gamma_rom_b[44]  = 'd101;
    gamma_rom_r[45]  = 'd103; gamma_rom_g[45]  = 'd103; gamma_rom_b[45]  = 'd103;
    gamma_rom_r[46]  = 'd104; gamma_rom_g[46]  = 'd104; gamma_rom_b[46]  = 'd104;
    gamma_rom_r[47]  = 'd105; gamma_rom_g[47]  = 'd105; gamma_rom_b[47]  = 'd105;
    gamma_rom_r[48]  = 'd106; gamma_rom_g[48]  = 'd106; gamma_rom_b[48]  = 'd106;
    gamma_rom_r[49]  = 'd108; gamma_rom_g[49]  = 'd108; gamma_rom_b[49]  = 'd108;
    gamma_rom_r[50]  = 'd109; gamma_rom_g[50]  = 'd109; gamma_rom_b[50]  = 'd109;
    gamma_rom_r[51]  = 'd110; gamma_rom_g[51]  = 'd110; gamma_rom_b[51]  = 'd110;
    gamma_rom_r[52]  = 'd111; gamma_rom_g[52]  = 'd111; gamma_rom_b[52]  = 'd111;
    gamma_rom_r[53]  = 'd112; gamma_rom_g[53]  = 'd112; gamma_rom_b[53]  = 'd112;
    gamma_rom_r[54]  = 'd114; gamma_rom_g[54]  = 'd114; gamma_rom_b[54]  = 'd114;
    gamma_rom_r[55]  = 'd115; gamma_rom_g[55]  = 'd115; gamma_rom_b[55]  = 'd115;
    gamma_rom_r[56]  = 'd116; gamma_rom_g[56]  = 'd116; gamma_rom_b[56]  = 'd116;
    gamma_rom_r[57]  = 'd117; gamma_rom_g[57]  = 'd117; gamma_rom_b[57]  = 'd117;
    gamma_rom_r[58]  = 'd118; gamma_rom_g[58]  = 'd118; gamma_rom_b[58]  = 'd118;
    gamma_rom_r[59]  = 'd119; gamma_rom_g[59]  = 'd119; gamma_rom_b[59]  = 'd119;
    gamma_rom_r[60]  = 'd120; gamma_rom_g[60]  = 'd120; gamma_rom_b[60]  = 'd120;
    gamma_rom_r[61]  = 'd121; gamma_rom_g[61]  = 'd121; gamma_rom_b[61]  = 'd121;
    gamma_rom_r[62]  = 'd123; gamma_rom_g[62]  = 'd123; gamma_rom_b[62]  = 'd123;
    gamma_rom_r[63]  = 'd124; gamma_rom_g[63]  = 'd124; gamma_rom_b[63]  = 'd124;
    gamma_rom_r[64]  = 'd125; gamma_rom_g[64]  = 'd125; gamma_rom_b[64]  = 'd125;
    gamma_rom_r[65]  = 'd126; gamma_rom_g[65]  = 'd126; gamma_rom_b[65]  = 'd126;
    gamma_rom_r[66]  = 'd127; gamma_rom_g[66]  = 'd127; gamma_rom_b[66]  = 'd127;
    gamma_rom_r[67]  = 'd128; gamma_rom_g[67]  = 'd128; gamma_rom_b[67]  = 'd128;
    gamma_rom_r[68]  = 'd129; gamma_rom_g[68]  = 'd129; gamma_rom_b[68]  = 'd129;
    gamma_rom_r[69]  = 'd130; gamma_rom_g[69]  = 'd130; gamma_rom_b[69]  = 'd130;
    gamma_rom_r[70]  = 'd131; gamma_rom_g[70]  = 'd131; gamma_rom_b[70]  = 'd131;
    gamma_rom_r[71]  = 'd132; gamma_rom_g[71]  = 'd132; gamma_rom_b[71]  = 'd132;
    gamma_rom_r[72]  = 'd133; gamma_rom_g[72]  = 'd133; gamma_rom_b[72]  = 'd133;
    gamma_rom_r[73]  = 'd134; gamma_rom_g[73]  = 'd134; gamma_rom_b[73]  = 'd134;
    gamma_rom_r[74]  = 'd135; gamma_rom_g[74]  = 'd135; gamma_rom_b[74]  = 'd135;
    gamma_rom_r[75]  = 'd136; gamma_rom_g[75]  = 'd136; gamma_rom_b[75]  = 'd136;
    gamma_rom_r[76]  = 'd137; gamma_rom_g[76]  = 'd137; gamma_rom_b[76]  = 'd137;
    gamma_rom_r[77]  = 'd138; gamma_rom_g[77]  = 'd138; gamma_rom_b[77]  = 'd138;
    gamma_rom_r[78]  = 'd139; gamma_rom_g[78]  = 'd139; gamma_rom_b[78]  = 'd139;
    gamma_rom_r[79]  = 'd140; gamma_rom_g[79]  = 'd140; gamma_rom_b[79]  = 'd140;
    gamma_rom_r[80]  = 'd141; gamma_rom_g[80]  = 'd141; gamma_rom_b[80]  = 'd141;
    gamma_rom_r[81]  = 'd142; gamma_rom_g[81]  = 'd142; gamma_rom_b[81]  = 'd142;
    gamma_rom_r[82]  = 'd142; gamma_rom_g[82]  = 'd142; gamma_rom_b[82]  = 'd142;
    gamma_rom_r[83]  = 'd143; gamma_rom_g[83]  = 'd143; gamma_rom_b[83]  = 'd143;
    gamma_rom_r[84]  = 'd144; gamma_rom_g[84]  = 'd144; gamma_rom_b[84]  = 'd144;
    gamma_rom_r[85]  = 'd145; gamma_rom_g[85]  = 'd145; gamma_rom_b[85]  = 'd145;
    gamma_rom_r[86]  = 'd146; gamma_rom_g[86]  = 'd146; gamma_rom_b[86]  = 'd146;
    gamma_rom_r[87]  = 'd147; gamma_rom_g[87]  = 'd147; gamma_rom_b[87]  = 'd147;
    gamma_rom_r[88]  = 'd148; gamma_rom_g[88]  = 'd148; gamma_rom_b[88]  = 'd148;
    gamma_rom_r[89]  = 'd149; gamma_rom_g[89]  = 'd149; gamma_rom_b[89]  = 'd149;
    gamma_rom_r[90]  = 'd150; gamma_rom_g[90]  = 'd150; gamma_rom_b[90]  = 'd150;
    gamma_rom_r[91]  = 'd151; gamma_rom_g[91]  = 'd151; gamma_rom_b[91]  = 'd151;
    gamma_rom_r[92]  = 'd151; gamma_rom_g[92]  = 'd151; gamma_rom_b[92]  = 'd151;
    gamma_rom_r[93]  = 'd152; gamma_rom_g[93]  = 'd152; gamma_rom_b[93]  = 'd152;
    gamma_rom_r[94]  = 'd153; gamma_rom_g[94]  = 'd153; gamma_rom_b[94]  = 'd153;
    gamma_rom_r[95]  = 'd154; gamma_rom_g[95]  = 'd154; gamma_rom_b[95]  = 'd154;
    gamma_rom_r[96]  = 'd155; gamma_rom_g[96]  = 'd155; gamma_rom_b[96]  = 'd155;
    gamma_rom_r[97]  = 'd156; gamma_rom_g[97]  = 'd156; gamma_rom_b[97]  = 'd156;
    gamma_rom_r[98]  = 'd156; gamma_rom_g[98]  = 'd156; gamma_rom_b[98]  = 'd156;
    gamma_rom_r[99]  = 'd157; gamma_rom_g[99]  = 'd157; gamma_rom_b[99]  = 'd157;
    gamma_rom_r[100] = 'd158; gamma_rom_g[100] = 'd158; gamma_rom_b[100] = 'd158;
    gamma_rom_r[101] = 'd159; gamma_rom_g[101] = 'd159; gamma_rom_b[101] = 'd159;
    gamma_rom_r[102] = 'd160; gamma_rom_g[102] = 'd160; gamma_rom_b[102] = 'd160;
    gamma_rom_r[103] = 'd161; gamma_rom_g[103] = 'd161; gamma_rom_b[103] = 'd161;
    gamma_rom_r[104] = 'd161; gamma_rom_g[104] = 'd161; gamma_rom_b[104] = 'd161;
    gamma_rom_r[105] = 'd162; gamma_rom_g[105] = 'd162; gamma_rom_b[105] = 'd162;
    gamma_rom_r[106] = 'd163; gamma_rom_g[106] = 'd163; gamma_rom_b[106] = 'd163;
    gamma_rom_r[107] = 'd164; gamma_rom_g[107] = 'd164; gamma_rom_b[107] = 'd164;
    gamma_rom_r[108] = 'd165; gamma_rom_g[108] = 'd165; gamma_rom_b[108] = 'd165;
    gamma_rom_r[109] = 'd165; gamma_rom_g[109] = 'd165; gamma_rom_b[109] = 'd165;
    gamma_rom_r[110] = 'd166; gamma_rom_g[110] = 'd166; gamma_rom_b[110] = 'd166;
    gamma_rom_r[111] = 'd167; gamma_rom_g[111] = 'd167; gamma_rom_b[111] = 'd167;
    gamma_rom_r[112] = 'd168; gamma_rom_g[112] = 'd168; gamma_rom_b[112] = 'd168;
    gamma_rom_r[113] = 'd169; gamma_rom_g[113] = 'd169; gamma_rom_b[113] = 'd169;
    gamma_rom_r[114] = 'd169; gamma_rom_g[114] = 'd169; gamma_rom_b[114] = 'd169;
    gamma_rom_r[115] = 'd170; gamma_rom_g[115] = 'd170; gamma_rom_b[115] = 'd170;
    gamma_rom_r[116] = 'd171; gamma_rom_g[116] = 'd171; gamma_rom_b[116] = 'd171;
    gamma_rom_r[117] = 'd172; gamma_rom_g[117] = 'd172; gamma_rom_b[117] = 'd172;
    gamma_rom_r[118] = 'd172; gamma_rom_g[118] = 'd172; gamma_rom_b[118] = 'd172;
    gamma_rom_r[119] = 'd173; gamma_rom_g[119] = 'd173; gamma_rom_b[119] = 'd173;
    gamma_rom_r[120] = 'd174; gamma_rom_g[120] = 'd174; gamma_rom_b[120] = 'd174;
    gamma_rom_r[121] = 'd175; gamma_rom_g[121] = 'd175; gamma_rom_b[121] = 'd175;
    gamma_rom_r[122] = 'd175; gamma_rom_g[122] = 'd175; gamma_rom_b[122] = 'd175;
    gamma_rom_r[123] = 'd176; gamma_rom_g[123] = 'd176; gamma_rom_b[123] = 'd176;
    gamma_rom_r[124] = 'd177; gamma_rom_g[124] = 'd177; gamma_rom_b[124] = 'd177;
    gamma_rom_r[125] = 'd178; gamma_rom_g[125] = 'd178; gamma_rom_b[125] = 'd178;
    gamma_rom_r[126] = 'd178; gamma_rom_g[126] = 'd178; gamma_rom_b[126] = 'd178;
    gamma_rom_r[127] = 'd179; gamma_rom_g[127] = 'd179; gamma_rom_b[127] = 'd179;
    gamma_rom_r[128] = 'd180; gamma_rom_g[128] = 'd180; gamma_rom_b[128] = 'd180;
    gamma_rom_r[129] = 'd180; gamma_rom_g[129] = 'd180; gamma_rom_b[129] = 'd180;
    gamma_rom_r[130] = 'd181; gamma_rom_g[130] = 'd181; gamma_rom_b[130] = 'd181;
    gamma_rom_r[131] = 'd182; gamma_rom_g[131] = 'd182; gamma_rom_b[131] = 'd182;
    gamma_rom_r[132] = 'd183; gamma_rom_g[132] = 'd183; gamma_rom_b[132] = 'd183;
    gamma_rom_r[133] = 'd183; gamma_rom_g[133] = 'd183; gamma_rom_b[133] = 'd183;
    gamma_rom_r[134] = 'd184; gamma_rom_g[134] = 'd184; gamma_rom_b[134] = 'd184;
    gamma_rom_r[135] = 'd185; gamma_rom_g[135] = 'd185; gamma_rom_b[135] = 'd185;
    gamma_rom_r[136] = 'd185; gamma_rom_g[136] = 'd185; gamma_rom_b[136] = 'd185;
    gamma_rom_r[137] = 'd186; gamma_rom_g[137] = 'd186; gamma_rom_b[137] = 'd186;
    gamma_rom_r[138] = 'd187; gamma_rom_g[138] = 'd187; gamma_rom_b[138] = 'd187;
    gamma_rom_r[139] = 'd188; gamma_rom_g[139] = 'd188; gamma_rom_b[139] = 'd188;
    gamma_rom_r[140] = 'd188; gamma_rom_g[140] = 'd188; gamma_rom_b[140] = 'd188;
    gamma_rom_r[141] = 'd189; gamma_rom_g[141] = 'd189; gamma_rom_b[141] = 'd189;
    gamma_rom_r[142] = 'd190; gamma_rom_g[142] = 'd190; gamma_rom_b[142] = 'd190;
    gamma_rom_r[143] = 'd190; gamma_rom_g[143] = 'd190; gamma_rom_b[143] = 'd190;
    gamma_rom_r[144] = 'd191; gamma_rom_g[144] = 'd191; gamma_rom_b[144] = 'd191;
    gamma_rom_r[145] = 'd192; gamma_rom_g[145] = 'd192; gamma_rom_b[145] = 'd192;
    gamma_rom_r[146] = 'd192; gamma_rom_g[146] = 'd192; gamma_rom_b[146] = 'd192;
    gamma_rom_r[147] = 'd193; gamma_rom_g[147] = 'd193; gamma_rom_b[147] = 'd193;
    gamma_rom_r[148] = 'd194; gamma_rom_g[148] = 'd194; gamma_rom_b[148] = 'd194;
    gamma_rom_r[149] = 'd194; gamma_rom_g[149] = 'd194; gamma_rom_b[149] = 'd194;
    gamma_rom_r[150] = 'd195; gamma_rom_g[150] = 'd195; gamma_rom_b[150] = 'd195;
    gamma_rom_r[151] = 'd196; gamma_rom_g[151] = 'd196; gamma_rom_b[151] = 'd196;
    gamma_rom_r[152] = 'd196; gamma_rom_g[152] = 'd196; gamma_rom_b[152] = 'd196;
    gamma_rom_r[153] = 'd197; gamma_rom_g[153] = 'd197; gamma_rom_b[153] = 'd197;
    gamma_rom_r[154] = 'd198; gamma_rom_g[154] = 'd198; gamma_rom_b[154] = 'd198;
    gamma_rom_r[155] = 'd198; gamma_rom_g[155] = 'd198; gamma_rom_b[155] = 'd198;
    gamma_rom_r[156] = 'd199; gamma_rom_g[156] = 'd199; gamma_rom_b[156] = 'd199;
    gamma_rom_r[157] = 'd200; gamma_rom_g[157] = 'd200; gamma_rom_b[157] = 'd200;
    gamma_rom_r[158] = 'd200; gamma_rom_g[158] = 'd200; gamma_rom_b[158] = 'd200;
    gamma_rom_r[159] = 'd201; gamma_rom_g[159] = 'd201; gamma_rom_b[159] = 'd201;
    gamma_rom_r[160] = 'd201; gamma_rom_g[160] = 'd201; gamma_rom_b[160] = 'd201;
    gamma_rom_r[161] = 'd202; gamma_rom_g[161] = 'd202; gamma_rom_b[161] = 'd202;
    gamma_rom_r[162] = 'd203; gamma_rom_g[162] = 'd203; gamma_rom_b[162] = 'd203;
    gamma_rom_r[163] = 'd203; gamma_rom_g[163] = 'd203; gamma_rom_b[163] = 'd203;
    gamma_rom_r[164] = 'd204; gamma_rom_g[164] = 'd204; gamma_rom_b[164] = 'd204;
    gamma_rom_r[165] = 'd205; gamma_rom_g[165] = 'd205; gamma_rom_b[165] = 'd205;
    gamma_rom_r[166] = 'd205; gamma_rom_g[166] = 'd205; gamma_rom_b[166] = 'd205;
    gamma_rom_r[167] = 'd206; gamma_rom_g[167] = 'd206; gamma_rom_b[167] = 'd206;
    gamma_rom_r[168] = 'd207; gamma_rom_g[168] = 'd207; gamma_rom_b[168] = 'd207;
    gamma_rom_r[169] = 'd207; gamma_rom_g[169] = 'd207; gamma_rom_b[169] = 'd207;
    gamma_rom_r[170] = 'd208; gamma_rom_g[170] = 'd208; gamma_rom_b[170] = 'd208;
    gamma_rom_r[171] = 'd208; gamma_rom_g[171] = 'd208; gamma_rom_b[171] = 'd208;
    gamma_rom_r[172] = 'd209; gamma_rom_g[172] = 'd209; gamma_rom_b[172] = 'd209;
    gamma_rom_r[173] = 'd210; gamma_rom_g[173] = 'd210; gamma_rom_b[173] = 'd210;
    gamma_rom_r[174] = 'd210; gamma_rom_g[174] = 'd210; gamma_rom_b[174] = 'd210;
    gamma_rom_r[175] = 'd211; gamma_rom_g[175] = 'd211; gamma_rom_b[175] = 'd211;
    gamma_rom_r[176] = 'd211; gamma_rom_g[176] = 'd211; gamma_rom_b[176] = 'd211;
    gamma_rom_r[177] = 'd212; gamma_rom_g[177] = 'd212; gamma_rom_b[177] = 'd212;
    gamma_rom_r[178] = 'd213; gamma_rom_g[178] = 'd213; gamma_rom_b[178] = 'd213;
    gamma_rom_r[179] = 'd213; gamma_rom_g[179] = 'd213; gamma_rom_b[179] = 'd213;
    gamma_rom_r[180] = 'd214; gamma_rom_g[180] = 'd214; gamma_rom_b[180] = 'd214;
    gamma_rom_r[181] = 'd214; gamma_rom_g[181] = 'd214; gamma_rom_b[181] = 'd214;
    gamma_rom_r[182] = 'd215; gamma_rom_g[182] = 'd215; gamma_rom_b[182] = 'd215;
    gamma_rom_r[183] = 'd216; gamma_rom_g[183] = 'd216; gamma_rom_b[183] = 'd216;
    gamma_rom_r[184] = 'd216; gamma_rom_g[184] = 'd216; gamma_rom_b[184] = 'd216;
    gamma_rom_r[185] = 'd217; gamma_rom_g[185] = 'd217; gamma_rom_b[185] = 'd217;
    gamma_rom_r[186] = 'd217; gamma_rom_g[186] = 'd217; gamma_rom_b[186] = 'd217;
    gamma_rom_r[187] = 'd218; gamma_rom_g[187] = 'd218; gamma_rom_b[187] = 'd218;
    gamma_rom_r[188] = 'd219; gamma_rom_g[188] = 'd219; gamma_rom_b[188] = 'd219;
    gamma_rom_r[189] = 'd219; gamma_rom_g[189] = 'd219; gamma_rom_b[189] = 'd219;
    gamma_rom_r[190] = 'd220; gamma_rom_g[190] = 'd220; gamma_rom_b[190] = 'd220;
    gamma_rom_r[191] = 'd220; gamma_rom_g[191] = 'd220; gamma_rom_b[191] = 'd220;
    gamma_rom_r[192] = 'd221; gamma_rom_g[192] = 'd221; gamma_rom_b[192] = 'd221;
    gamma_rom_r[193] = 'd221; gamma_rom_g[193] = 'd221; gamma_rom_b[193] = 'd221;
    gamma_rom_r[194] = 'd222; gamma_rom_g[194] = 'd222; gamma_rom_b[194] = 'd222;
    gamma_rom_r[195] = 'd223; gamma_rom_g[195] = 'd223; gamma_rom_b[195] = 'd223;
    gamma_rom_r[196] = 'd223; gamma_rom_g[196] = 'd223; gamma_rom_b[196] = 'd223;
    gamma_rom_r[197] = 'd224; gamma_rom_g[197] = 'd224; gamma_rom_b[197] = 'd224;
    gamma_rom_r[198] = 'd224; gamma_rom_g[198] = 'd224; gamma_rom_b[198] = 'd224;
    gamma_rom_r[199] = 'd225; gamma_rom_g[199] = 'd225; gamma_rom_b[199] = 'd225;
    gamma_rom_r[200] = 'd225; gamma_rom_g[200] = 'd225; gamma_rom_b[200] = 'd225;
    gamma_rom_r[201] = 'd226; gamma_rom_g[201] = 'd226; gamma_rom_b[201] = 'd226;
    gamma_rom_r[202] = 'd227; gamma_rom_g[202] = 'd227; gamma_rom_b[202] = 'd227;
    gamma_rom_r[203] = 'd227; gamma_rom_g[203] = 'd227; gamma_rom_b[203] = 'd227;
    gamma_rom_r[204] = 'd228; gamma_rom_g[204] = 'd228; gamma_rom_b[204] = 'd228;
    gamma_rom_r[205] = 'd228; gamma_rom_g[205] = 'd228; gamma_rom_b[205] = 'd228;
    gamma_rom_r[206] = 'd229; gamma_rom_g[206] = 'd229; gamma_rom_b[206] = 'd229;
    gamma_rom_r[207] = 'd229; gamma_rom_g[207] = 'd229; gamma_rom_b[207] = 'd229;
    gamma_rom_r[208] = 'd230; gamma_rom_g[208] = 'd230; gamma_rom_b[208] = 'd230;
    gamma_rom_r[209] = 'd231; gamma_rom_g[209] = 'd231; gamma_rom_b[209] = 'd231;
    gamma_rom_r[210] = 'd231; gamma_rom_g[210] = 'd231; gamma_rom_b[210] = 'd231;
    gamma_rom_r[211] = 'd232; gamma_rom_g[211] = 'd232; gamma_rom_b[211] = 'd232;
    gamma_rom_r[212] = 'd232; gamma_rom_g[212] = 'd232; gamma_rom_b[212] = 'd232;
    gamma_rom_r[213] = 'd233; gamma_rom_g[213] = 'd233; gamma_rom_b[213] = 'd233;
    gamma_rom_r[214] = 'd233; gamma_rom_g[214] = 'd233; gamma_rom_b[214] = 'd233;
    gamma_rom_r[215] = 'd234; gamma_rom_g[215] = 'd234; gamma_rom_b[215] = 'd234;
    gamma_rom_r[216] = 'd234; gamma_rom_g[216] = 'd234; gamma_rom_b[216] = 'd234;
    gamma_rom_r[217] = 'd235; gamma_rom_g[217] = 'd235; gamma_rom_b[217] = 'd235;
    gamma_rom_r[218] = 'd235; gamma_rom_g[218] = 'd235; gamma_rom_b[218] = 'd235;
    gamma_rom_r[219] = 'd236; gamma_rom_g[219] = 'd236; gamma_rom_b[219] = 'd236;
    gamma_rom_r[220] = 'd236; gamma_rom_g[220] = 'd236; gamma_rom_b[220] = 'd236;
    gamma_rom_r[221] = 'd237; gamma_rom_g[221] = 'd237; gamma_rom_b[221] = 'd237;
    gamma_rom_r[222] = 'd238; gamma_rom_g[222] = 'd238; gamma_rom_b[222] = 'd238;
    gamma_rom_r[223] = 'd238; gamma_rom_g[223] = 'd238; gamma_rom_b[223] = 'd238;
    gamma_rom_r[224] = 'd239; gamma_rom_g[224] = 'd239; gamma_rom_b[224] = 'd239;
    gamma_rom_r[225] = 'd239; gamma_rom_g[225] = 'd239; gamma_rom_b[225] = 'd239;
    gamma_rom_r[226] = 'd240; gamma_rom_g[226] = 'd240; gamma_rom_b[226] = 'd240;
    gamma_rom_r[227] = 'd240; gamma_rom_g[227] = 'd240; gamma_rom_b[227] = 'd240;
    gamma_rom_r[228] = 'd241; gamma_rom_g[228] = 'd241; gamma_rom_b[228] = 'd241;
    gamma_rom_r[229] = 'd241; gamma_rom_g[229] = 'd241; gamma_rom_b[229] = 'd241;
    gamma_rom_r[230] = 'd242; gamma_rom_g[230] = 'd242; gamma_rom_b[230] = 'd242;
    gamma_rom_r[231] = 'd242; gamma_rom_g[231] = 'd242; gamma_rom_b[231] = 'd242;
    gamma_rom_r[232] = 'd243; gamma_rom_g[232] = 'd243; gamma_rom_b[232] = 'd243;
    gamma_rom_r[233] = 'd243; gamma_rom_g[233] = 'd243; gamma_rom_b[233] = 'd243;
    gamma_rom_r[234] = 'd244; gamma_rom_g[234] = 'd244; gamma_rom_b[234] = 'd244;
    gamma_rom_r[235] = 'd244; gamma_rom_g[235] = 'd244; gamma_rom_b[235] = 'd244;
    gamma_rom_r[236] = 'd245; gamma_rom_g[236] = 'd245; gamma_rom_b[236] = 'd245;
    gamma_rom_r[237] = 'd245; gamma_rom_g[237] = 'd245; gamma_rom_b[237] = 'd245;
    gamma_rom_r[238] = 'd246; gamma_rom_g[238] = 'd246; gamma_rom_b[238] = 'd246;
    gamma_rom_r[239] = 'd246; gamma_rom_g[239] = 'd246; gamma_rom_b[239] = 'd246;
    gamma_rom_r[240] = 'd247; gamma_rom_g[240] = 'd247; gamma_rom_b[240] = 'd247;
    gamma_rom_r[241] = 'd247; gamma_rom_g[241] = 'd247; gamma_rom_b[241] = 'd247;
    gamma_rom_r[242] = 'd248; gamma_rom_g[242] = 'd248; gamma_rom_b[242] = 'd248;
    gamma_rom_r[243] = 'd248; gamma_rom_g[243] = 'd248; gamma_rom_b[243] = 'd248;
    gamma_rom_r[244] = 'd249; gamma_rom_g[244] = 'd249; gamma_rom_b[244] = 'd249;
    gamma_rom_r[245] = 'd250; gamma_rom_g[245] = 'd250; gamma_rom_b[245] = 'd250;
    gamma_rom_r[246] = 'd250; gamma_rom_g[246] = 'd250; gamma_rom_b[246] = 'd250;
    gamma_rom_r[247] = 'd251; gamma_rom_g[247] = 'd251; gamma_rom_b[247] = 'd251;
    gamma_rom_r[248] = 'd251; gamma_rom_g[248] = 'd251; gamma_rom_b[248] = 'd251;
    gamma_rom_r[249] = 'd252; gamma_rom_g[249] = 'd252; gamma_rom_b[249] = 'd252;
    gamma_rom_r[250] = 'd252; gamma_rom_g[250] = 'd252; gamma_rom_b[250] = 'd252;
    gamma_rom_r[251] = 'd253; gamma_rom_g[251] = 'd253; gamma_rom_b[251] = 'd253;
    gamma_rom_r[252] = 'd253; gamma_rom_g[252] = 'd253; gamma_rom_b[252] = 'd253;
    gamma_rom_r[253] = 'd254; gamma_rom_g[253] = 'd254; gamma_rom_b[253] = 'd254;
    gamma_rom_r[254] = 'd254; gamma_rom_g[254] = 'd254; gamma_rom_b[254] = 'd254;
    gamma_rom_r[255] = 'd255; gamma_rom_g[255] = 'd255; gamma_rom_b[255] = 'd255;
end

always_ff @(posedge clock_in) begin

    red_data_out <= gamma_rom_r[red_data_in] + 1;
    green_data_out <= gamma_rom_g[green_data_in] + 1;
    blue_data_out <= gamma_rom_b[blue_data_in] + 1;

    line_valid_out <= line_valid_in;
    frame_valid_out <= frame_valid_in;

    // if(reset_n_in == 0 || frame_valid_in == 0 || line_valid_in == 0) begin
    // end
    
    // else begin
    // end
   
end
    
endmodule