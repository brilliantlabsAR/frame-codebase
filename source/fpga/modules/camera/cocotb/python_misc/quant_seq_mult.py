import os
aw = 11 + 4  # 11 bits signed coeff + 4 aan
bw = 13
zw = aw + bw
stages = 4

print ('// auto-generated by:', os.path.basename(__file__))
hdr = f'''module quant_seq_mult_{aw}x{bw}_p{stages} (
    input   logic signed[{aw-1}:0] a_in,
    input   logic unsigned[{bw-1}:0] b_in,
    output  logic signed[{zw-1}:0] out,
    input   logic in_valid,
    output  logic out_valid,
    input   logic en,
    input   logic clk,
    input   logic resetn
);'''
print (hdr)

for p in ['a', 'b', 'z', 'valid']:
    t = '' if p == 'valid' else 'signed[{}:0] '.format({'a': aw, 'b': bw, 'z': zw}[p] - 1)
    for q in ['', '_next']:
        x = 'logic {}{};'.format(t, ', '.join([f'{p}_pipe_stg{i}{q}' for i in range(stages)]))
        print (x)

print ('always @(posedge clk) if (!resetn) begin')
for i in reversed(range(stages)):
    print (f'    valid_pipe_stg{i} <= 0;')
print ('end else if(en) begin')
for i in reversed(range(stages)):
    print (f'    valid_pipe_stg{i} <= valid_pipe_stg{i}_next;')
print ('end')

print ('always @(posedge clk) if(en) begin')
for p in ['a', 'b', 'z']:
    for i in reversed(range(stages)):
        iff = f'if (valid_pipe_stg{i}_next) '
        print (f'    {iff}{p}_pipe_stg{i} <= {p}_pipe_stg{i}_next;')
print ('end')

z = bw
print ('always_comb begin')
for p in ['valid', 'a', 'b', 'z']:
    for i in reversed(range(stages)):
        k = i - 1
        x = f'{p}_pipe_stg{i}_next'
        y = '{};'.format({'a': 'a_in', 'b': 'b_in', 'z': '0', 'valid': 'in_valid'}[p]) if i==0 else f'{p}_pipe_stg{k};'
        print (f'    {x} = {y}')

        if p == 'z':
            if i == stages - 1:
                # rounding bit .5 round to even - matches python round
                print (f'    {x} = {x} + (a_pipe_stg{i}_next[{bw-1}] << {bw-2});')
        
            d = i + 1
            t = z//d
            z_new = z - t

            for j in reversed(range(z_new, z)):
                print(f'    {x} = {x} + (b_pipe_stg{i}_next[{j}] ? (a_pipe_stg{i}_next << {j}) : 0);')
            z = z_new
print ('end')


print ('always_comb out = z_pipe_stg{};'.format(stages - 1))
print ('always_comb out_valid = valid_pipe_stg{};'.format(stages - 1))

print ('endmodule')
