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

    input         flip,
    output        pxl_cen,
    output        pxl2_cen,

    output        LHBL,
    output        LVBL,
    output        HS,
    output        VS,

    input  [11:0] main_addr,
    input  [ 7:0] main_dout,
    input         main_rnw,

    input  [ 8:0] scr1pos,
    input         scr1_ramcs,
    output [16:0] scr1_addr,
    input  [31:0] scr1_data,
    output [ 7:0] scr1_dout,
    output        scr1_cs,
    input         scr1_ok,

    input  [10:0] scr2pos,
    input  [ 2:0] scr2col,
    output [17:0] scr2_addr,
    input  [31:0] scr2_data,
    output        scr2_cs,
    input         scr2_ok,
    input         scr2enb,

    input         oram_cs,
    output [17:0] obj_addr,
    input  [31:0] obj_data,
    output        obj_cs,
    input         obj_ok,

    input         pal_cs,
    output [ 7:0] pal_dout,

    output [ 4:0] red,
    output [ 4:0] green,
    output [ 4:0] blue,

    input  [ 3:0] gfx_en,
    input  [ 7:0] debug_bus
);

wire [8:0] h;
wire [8:0] v, vrender;
wire [3:0] scr2_pxl;
wire [7:0] scr1_pxl, obj_pxl;


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
    .vdump      ( v         ),
    .vrender    ( vrender   ),
    .vrender1   (           ),
    .H          ( h         ),
    .Hinit      (           ),
    .Vinit      (           ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .HS         ( HS        ),
    .VS         ( VS        )
);

jtvigil_scr1 u_scr1 (
    .rst      ( rst         ),
    .clk      ( clk         ),
    .clk_cpu  ( clk_cpu     ),
    .pxl_cen  ( pxl_cen     ),
    .flip     ( flip        ),
    .main_addr( main_addr   ),
    .main_dout( main_dout   ),
    .main_din ( scr1_dout   ),
    .main_rnw ( main_rnw    ),
    .scr1_cs  ( scr1_ramcs  ),
    .h        ( h           ),
    .v        ( v           ),
    .scrpos   ( scr1pos     ),
    .rom_addr ( scr1_addr   ),
    .rom_data ( scr1_data   ),
    .rom_cs   ( scr1_cs     ),
    .rom_ok   ( scr1_ok     ),
    .pxl      ( scr1_pxl    )
);

jtvigil_scr2 u_scr2 (
    .rst        ( rst         ),
    .clk        ( clk         ),
    .pxl_cen    ( pxl_cen     ),
    .flip       ( flip        ),
    .h          ( h           ),
    .v          ( v           ),
    .scrpos     ( scr2pos     ),
    .rom_addr   ( scr2_addr   ),
    .rom_data   ( scr2_data   ),
    .rom_cs     ( scr2_cs     ),
    .rom_ok     ( scr2_ok     ),
    .pxl        ( scr2_pxl    )
);


jtvigil_obj u_obj (
    .rst      ( rst            ),
    .clk      ( clk            ),
    .clk_cpu  ( clk_cpu        ),
    .pxl_cen  ( pxl_cen        ),
    .flip     ( flip           ),
    .LHBL     ( LHBL           ),
    .main_addr( main_addr[7:0] ),
    .main_dout( main_dout      ),
    .oram_cs  ( oram_cs        ),
    .h        ( h              ),
    .v        ( vrender        ),
    .rom_addr ( obj_addr       ),
    .rom_data ( obj_data       ),
    .rom_cs   ( obj_cs         ),
    .rom_ok   ( obj_ok         ),
    .pxl      ( obj_pxl        )
);

jtvigil_colmix u_colmix (
    .rst      ( rst            ),
    .clk      ( clk            ),
    .clk_cpu  ( clk_cpu        ),
    .pxl_cen  ( pxl_cen        ),
    .LHBL     ( LHBL           ),
    .LVBL     ( LVBL           ),
    .main_addr( main_addr[10:0]), // TODO: Check connection ! Signal/port not matching : Expecting logic [10:0]  -- Found logic [11:0]
    .main_dout( main_dout      ),
    .main_din ( pal_dout       ),
    .main_rnw ( main_rnw       ),
    .pal_cs   ( pal_cs         ),
    .scr1_pxl ( scr1_pxl       ),
    .scr2col  ( scr2col        ),
    .scr2_pxl ( scr2_pxl       ),
    .obj_pxl  ( obj_pxl        ),
    .gfx_en   ( gfx_en         ),
    .red      ( red            ),
    .green    ( green          ),
    .blue     ( blue           )
);


endmodule