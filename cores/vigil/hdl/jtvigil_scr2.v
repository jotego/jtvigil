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
    input         flip,

    input  [ 8:0] h,
    input  [ 8:0] v,
    input         LVBL,
    input  [10:0] scrpos,
    output [17:0] rom_addr,
    input  [31:0] rom_data, // 32/4 = 8 pixels
    output        rom_cs,
    input         rom_ok,
    output [ 3:0] pxl,
    input  [ 7:0] debug_bus
);

reg  [11:0] hsum;
reg  [31:0] pxl_data;

assign rom_cs   = LVBL;
assign rom_addr = { /*debug_bus[7:4]*/ 1'b0, hsum[10:9],
    v[7:0], hsum[8:3], ~flip };
assign pxl = hsum[0] /*^ flip*/ ?
    { pxl_data[6], pxl_data[4], pxl_data[2], pxl_data[0] } :
    { pxl_data[7], pxl_data[5], pxl_data[3], pxl_data[1] };

always @(posedge clk) if(pxl_cen) begin
    hsum <= { 2'b11, h^{9{~flip}} } + scrpos + 9'h80;
    case( hsum[2:0] )   // 8 pixel delay
        0: pxl_data <= ~flip ?
            { rom_data[15:0], rom_data[31:16] } :
            rom_data;
        2,4,6: begin
            pxl_data <= pxl_data >> 8;
        end
    endcase
end
/*
jtframe_dual_ram u_buffer (
    .clk0 ( clk      ),
    .data0( pxl_data ),
    .addr0( addr0),
    .we0  (we0  ),
    .q0   (q0   ),
    .clk1 (clk1 ),
    .data1(data1),
    .addr1(addr1),
    .we1  (we1  )
);*/


endmodule