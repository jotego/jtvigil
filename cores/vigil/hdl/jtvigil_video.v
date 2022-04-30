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

module jtvigil_video(
    input         rst,
    input         clk,
    input         clk_cpu,
    output        pxl_cen,
    output        pxl2_cen,
    output        LHBL_dly,
    output        LVBL_dly,
    output        LVBL,
    output [17:0] scr1_addr,
    input  [31:0] scr1_data,
    input         scr1_cs,
    input         scr1_ok,
    output [17:0] scr2_addr,
    input  [31:0] scr2_data,
    input         scr2_cs,
    input         scr2_ok,
    input  [ 3:0] gfx_en,
    input  [ 3:0] debug_bus
);

jtframe_cen48 u_cen48(
    .clk    ( clk      ),    // 48 MHz
    .cen12  ( pxl2_cen ),
    .cen16  (          ),
    .cen8   (          ),
    .cen6   ( pxl_cen  ),
    .cen4   (          ),
    .cen4_12(          ),
    .cen3   (          ),
    .cen3q  (          ),
    .cen1p5 (          ),
    .cen16b (          ),
    .cen12b (          ),
    .cen6b  (          ),
    .cen3b  (          ),
    .cen3qb (          ),
    .cen1p5b(          )
);

// HSync lasts for 32 pixels, from pixel 48 to 80. Blanking is 128 pxl
// 55 Hz according to MAME
jtframe_vtimer #(
    .V_START  ( 9'd0            ),
    .VB_START ( 9'd255          ),
    .VB_END   ( 9'd279          ),
    .VS_START ( 9'd260          ),
    .HB_END   ( 9'd383          ),
    .HB_START ( 9'd255          ),
    .HS_START ( 9'd304          ),
    .HS_END   ( 9'd336          )
) u_vtimer(
    .clk        ( clk       ),
    .pxl_cen    ( pxl_cen   ),
    .vdump      ( vdump     ),
    .vrender    ( vrender   ),
    .vrender1   ( vrender1  ),
    .H          ( H         ),
    .Hinit      ( Hinit     ),
    .Vinit      ( Vinit     ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .HS         ( HS        ),
    .VS         ( VS        )
);

endmodule