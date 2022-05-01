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

module jtvigil_obj(
    input         rst,
    input         clk,
    input         clk_cpu,
    input         pxl_cen,
    input         flip,
    input         LHBL,

    input  [ 7:0] main_addr,
    input  [ 7:0] main_dout,
    input         oram_cs,

    input  [ 8:0] h,
    input  [ 8:0] v,
    output [16:0] rom_addr,
    input  [31:0] rom_data,
    output        rom_cs,
    input         rom_ok,
    output [ 7:0] pxl
);

// Addr   |  Usage
//   0    |  3:0 - palette
//   2    | Y
//   3    | 0 - Y msb
//   4    |  code
//   5    |  7:6 - vflip, hflip, 5:4 v size, 3:0 - code MSB
//   6    |  X
//   7    |  0 - X msb

reg  [ 4:0] obj_cnt;
reg  [ 2:0] sub_cnt;
reg         aux_cen, LHBL_l, done, dr_start;
reg  [ 3:0] pal;
reg  [ 8:0] xpos, ypos;
reg  [11:0] code;
reg         vflip, hflip;
reg  [ 1:0] hsize;

// The original address multiplexer only lets
// the CPU address go through while in V blanking
jtframe_dual_ram #(.aw(8)) u_vram(
    // CPU
    .clk0 ( clk_cpu   ),
    .addr0( main_addr ),
    .data0( main_dout ),
    .we0  ( oram_cs   ),
    .q0   (           ),
    // Tilemap scan
    .clk1 ( clk       ),
    .addr1( scan_addr ),
    .data1(           ),
    .we1  ( 1'b0      ),
    .q1   ( scan_dout )
);

// Table scan
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        obj_cnt <= 0;
        sub_cnt <= 0;
        aux_cen <= 0;
    end else if(aux_cen) begin
        LHBL_l   <= LHBL;
        dr_start <= 0;
        if( LHBL && !LHBL_l ) begin
            done    <= 0;
            obj_cnt <= 0;
            sub_cnt <= 0;
        end
        if( !done ) begin
            if( sub_cnt!=7 ) sub_cnt <= sub_cnt + 3'd1;
            // Grab data
            case( sub_cnt )
                0: pal       <= scan_dout[3:0];
                2: ypos[7:0] <= scan_dout;
                3: ypos[8]   <= scan_dout[0];
                4: code[7:0] <= scan_dout;
                5: { vflip, hflip, hsize, code[11:8] } <= scan_dout;
                6: xpos[7:0] <= scan_dout;
                7: xpos[8]   <= scan_dout[0];
            endcase
            if( sub_cnt==7 ) begin
                if( !match || (match && !dr_busy ) ) begin
                    obj_cnt <= obj_cnt + 5'd1;
                    sub_cnt <= 0;
                    if( &obj_cnt ) done <= 1;
                end
                if( !dr_busy ) dr_start <= match;
            end
        end
    end
end

// Draw

jtframe_obj_buffer u_obj_buffer (
    .clk     ( clk         ),
    .LHBL    ( LHBL        ),
    .flip    ( flip        ),
    .wr_data ( buf_data    ),
    .wr_addr ( buf_addr    ),
    .we      ( buf_we      ),
    .rd_addr ( h           ),
    .rd      ( pxl_cen     ),
    .rd_data ( pxl         )
);

endmodule