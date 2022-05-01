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
    Date: 1-5-2022 */

module jtvigil_scr1(
    input         rst,
    input         clk,
    input         clk_cpu,
    input         pxl_cen,
    input         flip,

    input  [11:0] main_addr,
    input  [ 7:0] main_dout,
    output [ 7:0] main_din,
    input         main_rnw,
    input         scr1_cs,

    input  [ 8:0] h,
    input  [ 8:0] v,
    input  [ 8:0] scrpos,
    output [16:0] rom_addr,
    input  [31:0] rom_data, // 32/4 = 8 pixels
    output        rom_cs,
    input         rom_ok,
    output [ 7:0] pxl
);

reg  [ 9:0] hsum;
reg  [31:0] pxl_data;
reg  [ 3:0] pal;

// Scan
wire        ram_we;
wire [11:0] scan_addr;
wire [ 7:0] scan_dout;
reg  [ 7:0] pre_code, code, attr;

assign ram_we   = scr1_cs & ~main_rnw;
assign rom_cs   = 1;
assign rom_addr = { attr[3:0], code, v[2:0], 2'b0 };
assign pxl = { pal, flip ?
    { pxl_data[7], pxl_data[5], pxl_data[3], pxl_data[1] } :
    { pxl_data[6], pxl_data[4], pxl_data[2], pxl_data[0] } };
assign scan_addr = { v[8], v[6:3], hsum[8], hsum[0], hsum[7:3] };

jtframe_dual_ram #(.aw(12)) u_vram(
    // CPU
    .clk0 ( clk_cpu   ),
    .addr0( main_addr ),
    .data0( main_dout ),
    .we0  ( ram_we    ),
    .q0   ( main_din  ),
    // Tilemap scan
    .clk1 ( clk       ),
    .addr1( scan_addr ),
    .data1(           ),
    .we1  ( 1'b0      ),
    .q1   ( scan_dout )
);

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        hsum     <= 0;
    end else if(pxl_cen) begin
        hsum     <= { 1'd0, h } + scrpos;
        case( hsum[2:0] )
            0: pre_code <= scan_dout;
            1: begin
                code <= pre_code;
                attr <= scan_dout;
            end
        endcase
    end
end

always @(posedge clk) if(pxl_cen) begin
    case( hsum[2:0] )   // 8 pixel delay
        0: begin
            pxl_data <= flip ? {rom_data[15:0], rom_data[31:16]} : rom_data;
            pal      <= attr[7:4];
        end
        4: pxl_data[15:0] <= pxl_data[31:16];
        default: begin
            pxl_data[15:0] <= flip ? pxl_data[15:0] << 1 : pxl_data[15:0] >> 1;
        end
    endcase
end

endmodule