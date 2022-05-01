/*  This file is part of JTVIGIL.
    JTVIGIL program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTVIGIL program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTVIGIL.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 30-4-2022 */

module jtvigil_scr2(
    input         rst,
    input         clk,
    input         pxl_cen,

    input  [ 8:0] h,
    input  [ 8:0] v,
    input  [10:0] scrpos,
    output [17:0] rom_addr,
    input  [31:0] rom_data, // 32/4 = 8 pixels
    output        rom_cs,
    input         rom_ok,
    output [ 3:0] pxl
);

reg  [10:0] hsum;
reg  [31:0] pxl_data;
wire [ 7:0] pxl_pair;

assign rom_cs   = 1;
assign rom_addr = { hsum[10:9], v[7:0], hsum[8:3], 2'b0 };
assign pxl_pair = flip ? pxl_data[31:24] : pxl_data[7:0];
assign pxl = ~hsum[0] ^ flip ?
    { pxl_pair[7], pxl_pair[5], pxl_pair[3], pxl_pair[1] } :
    { pxl_pair[6], pxl_pair[4], pxl_pair[2], pxl_pair[0] };

always @(posedge clk) if(pxl_cen) begin
    hsum <= { 2'd0, h } + scrpos;
    case( hsum[2:0] )   // 8 pixel delay
        0: pxl_data <= rom_data;
        2,4,6: begin
            pxl_data <= flip ? pxl_data << 8 : pxl_data >> 8;
        end
    endcase
end

endmodule