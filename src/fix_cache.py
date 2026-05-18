import re

with open('Mainv3.v', 'r', encoding='utf-8') as f:
    content = f.read()

# 256 -> 64 lines for both caches
content = content.replace('[0:255]', '[0:63]')

# idx from addr[11:4] (8-bit) -> addr[9:4] (6-bit), req_tag from addr[31:12](20-bit) -> addr[31:10](22-bit)
content = content.replace('wire [7:0]  idx      = cpu_addr[11:4];', 'wire [5:0]  idx      = cpu_addr[9:4];')
content = content.replace('wire [19:0] req_tag  = cpu_addr[31:12];', 'wire [21:0] req_tag  = cpu_addr[31:10];')

# req_tag_reg width 19:0 -> 21:0
content = content.replace('reg [19:0]  req_tag_reg;', 'reg [21:0]  req_tag_reg;')

# hit check: tag_out[20] & tag_out[19:0] -> tag_out[22] & tag_out[21:0]
# ICache: tag_out[20] & (tag_out[19:0] == req_tag_reg)
# DCache: tag_out[21] & (tag_out[21:0] == {1'b1, req_tag_reg}) <- wrong, fix properly
content = content.replace(
    'cache_hit_reg <= tag_out[20] & (tag_out[19:0] == req_tag_reg);',
    'cache_hit_reg <= tag_out[22] & (tag_out[21:0] == req_tag_reg);'
)
content = content.replace(
    'cache_hit_reg <= tag_out[21] & (tag_out[21:0] == {1\'b1, req_tag_reg});',
    'cache_hit_reg <= tag_out[22] & (tag_out[21:0] == req_tag_reg);'
)

# fill address: fill_addr[11:4] -> fill_addr[9:4]
content = content.replace('data_mem[fill_addr[11:4]]', 'data_mem[fill_addr[9:4]]')
content = content.replace('tag_mem [fill_addr[11:4]]', 'tag_mem [fill_addr[9:4]]')
content = content.replace("tag_mem [fill_addr[11:4]] <= {11'd0, 1'b1, fill_addr[31:12]}", 
                           "tag_mem [fill_addr[9:4]]  <= {9'd0, 1'b1, fill_addr[31:10]}")
content = content.replace("{11'd0, 1'b1, fill_addr[31:12]}", "{9'd0, 1'b1, fill_addr[31:10]}")

# tag_wr_addr
content = content.replace('wire [7:0]  tag_wr_addr = fill_en ? fill_addr[11:4] : inv_addr[11:4];',
                           'wire [5:0]  tag_wr_addr = fill_en ? fill_addr[9:4] : inv_addr[9:4];')
content = content.replace('wire [7:0]  tag_wr_addr = fill_en ? fill_addr[9:4] : inv_addr[9:4];',
                           'wire [5:0]  tag_wr_addr = fill_en ? fill_addr[9:4] : inv_addr[9:4];')
content = content.replace("wire [31:0] tag_wr_data = fill_en ? {11'd0, 1'b1, fill_addr[31:12]} : 32'd0;",
                           "wire [31:0] tag_wr_data = fill_en ? {9'd0, 1'b1, fill_addr[31:10]} : 32'd0;")

# init loops
content = content.replace('for (ci1 = 0; ci1 < 256; ci1 = ci1 + 1)', 'for (ci1 = 0; ci1 < 64; ci1 = ci1 + 1)')
content = content.replace('for (ci2 = 0; ci2 < 256; ci2 = ci2 + 1)', 'for (ci2 = 0; ci2 < 64; ci2 = ci2 + 1)')

with open('Mainv3.v', 'w', encoding='utf-8') as f:
    f.write(content)

print('Done - cache shrunk to 64 lines')
