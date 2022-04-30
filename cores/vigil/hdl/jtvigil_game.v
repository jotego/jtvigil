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

module jtvigil_game(
    input           rst,
    input           clk,
    input           rst24,
    input           clk24,
    output          pxl2_cen,   // 12   MHz
    output          pxl_cen,    //  6   MHz
    output   [7:0]  red,
    output   [7:0]  green,
    output   [7:0]  blue,
    output          LHBL_dly,
    output          LVBL_dly,
    output          HS,
    output          VS,
    // cabinet I/O
    input   [ 1:0]  start_button,
    input   [ 1:0]  coin_input,
    input   [ 8:0]  joystick1,
    input   [ 8:0]  joystick2,

    // SDRAM interface
    input           downloading,
    output          dwnld_busy,

    // Bank 0: allows R/W
    output   [21:0] ba0_addr,
    output   [21:0] ba1_addr,
    output   [21:0] ba2_addr,
    output   [21:0] ba3_addr,
    output   [ 3:0] ba_rd,
    input    [ 3:0] ba_ack,
    input    [ 3:0] ba_dst,
    input    [ 3:0] ba_dok,
    input    [ 3:0] ba_rdy,

    input    [15:0] data_read,

    // RAM/ROM LOAD
    input   [24:0]  ioctl_addr,
    input   [ 7:0]  ioctl_dout,
    input           ioctl_wr,
    output  [21:0]  prog_addr,
    output  [15:0]  prog_data,
    output  [ 1:0]  prog_mask,
    output  [ 1:0]  prog_ba,
    output          prog_we,
    output          prog_rd,
    input           prog_ack,
    input           prog_dok,
    input           prog_dst,
    input           prog_rdy,
    // DIP switches
    input   [31:0]  status,
    input   [31:0]  dipsw,
    input           service,
    input           dip_pause,
    output          dip_flip,
    input           dip_test,
    input   [ 1:0]  dip_fxlevel, // Not a DIP on the original PCB
    // Sound output
    output  signed [15:0] snd,
    output          sample,
    output          game_led,
    input           enable_psg,
    input           enable_fm,
    // Debug
    input   [3:0]   gfx_en,
    input   [7:0]   debug_bus,
    output  [7:0]   debug_view
);

// video signals
wire        LVBL, LHBL;

// SDRAM interface
wire        main_cs, scr1_cs, scr2_cs, obj_cs, adpcm_cs;
wire [17:0] main_addr;
wire [ 7:0] main_data, snd_data, adpcm_data;
wire [31:0] scr1_data, scr2_data, obj_data;
wire        main_ok, scr1_ok, scr2_ok, obj_ok, adpck_ok;

// CPU interface
wire [ 7:0] main_dout, pal_dout, obj_dout;
wire        main_rnw;

// Scroll configuration
wire [10:0] scr1pos, scr2pos;
wire [ 2:0] scr2col;

// Cabinet inputs
wire [ 7:0] dipsw_a, dipsw_b;


assign { dipsw_b, dipsw_a } = dipsw[15:0];
assign dip_flip = ~flip;

jtframe_cen3p57 #(.CLK24(1)) u_cencpu(
    .clk        ( clk24     ),
    .cen_3p57   ( cpu_cen   ),
    .cen_1p78   (           )
);

jtvigil_main u_main(
    .rst        ( rst24     ),
    .clk        ( clk24     ),
    // Video
    .LVBL       ( LVBL      ),
    // Sound communication
    .latch_cs   ( snd_latch ),
    // Palette
    .pal_cs     ( pal_cs    ),
    .pal_dout   ( pal_dout  ),
    // Video circuitry

    // Objects
    .obj_cs     ( objram_cs ),
    .obj_copy   ( obj_copy  ),
    .obj_dout   ( obj_dout  ),

    // CPU bus
    .cpu_addr   ( main_addr ),
    .cpu_dout   ( main_dout ),
    .UDSWn      ( UDSWn     ),
    .LDSWn      ( LDSWn     ),
    .RnW        ( main_rnw  ),
    // cabinet I/O
    .joystick1   ( joystick1  ),
    .joystick2   ( joystick2  ),
    .start_button(start_button),
    .coin_input  ( coin_input ),
    .service     ( service    ),
    // ROM access
    .rom_cs      ( main_cs    ),
    .rom_data    ( main_data  ),
    .rom_ok      ( main_ok    ),
    // DIP switches
    .dip_pause   ( dip_pause  ),
    .dipsw_a     ( dipsw_a    ),
    .dipsw_b     ( dipsw_b    )
);

jtvigil_video u_video(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .clk_cpu    ( clk24     ),
    .pxl2_cen   ( pxl2_cen  ),
    .pxl_cen    ( pxl_cen   ),
    .gfx_en     ( gfx_en    ),

    // CPU interface
    .cpu_addr   ( main_addr[12:0]  ),
    .cpu_dout   ( main_dout ),
    .cpu_rnw    ( main_rnw  ),

    // Scroll
    .scr1_cs    ( scr1_cs   ),
    .scr1_ok    ( scr1_ok   ),
    .scr1_addr  ( scr1_addr ),
    .scr1_data  ( scr1_data ),

    .scr2pos    ( scr2pos   ),
    .scr2_cs    ( scr2_cs   ),
    .scr2_ok    ( scr2_ok   ),
    .scr2_addr  ( scr2_addr ),
    .scr2_data  ( scr2_data ),

    // Object
    .objram_cs  ( objram_cs ),
    .obj_dout   ( obj_dout  ),
    .obj_copy   ( obj_copy  ),

    // Palette
    .pal_cs     ( pal_cs    ),
    .pal_dout   ( pal_dout  ),
    .flip       ( flip      ),

    // SDRAM interface

    .orom_ok     ( obj_ok     ),
    .orom_cs     ( obj_cs     ),
    .orom_addr   ( obj_addr   ),
    .orom_data   ( obj_data   ),

    // Video signal
    .HS         ( HS        ),
    .VS         ( VS        ),
    .LVBL       ( LVBL      ),
    .LHBL       ( LHBL      ),
    .LHBL_dly   ( LHBL_dly  ),
    .LVBL_dly   ( LVBL_dly  ),
    .red        ( red       ),
    .green      ( green     ),
    .blue       ( blue      ),
    .debug_bus  ( debug_bus )
);

`ifndef NOSOUND
    jtvigil_snd u_sound(
        .rst        ( rst24     ),
        .clk        ( clk24     ),
        .cpu_cen    ( cpu_cen   ),

        // From main CPU
        .snreq      ( snreq     ),
        .latch      ( snd_latch ),
        .snd_bank   ( snd_bank  ),

        // ROM
        .rom_addr   ( snd_addr  ),
        .rom_cs     ( snd_cs    ),
        .rom_data   ( snd_data  ),
        .rom_ok     ( snd_ok    ),

        // ADPCM ROM
        .adpcm_addr ( adpcm_addr),
        .adpcm_cs   ( adpcm_cs  ),
        .adpcm_data ( adpcm_data),
        .adpcm_ok   ( adpcm_ok  ),

        .snd        ( snd       ),
        .sample     ( sample    ),
        .peak       ( game_led  )
    );
`else
    assign snd_cs   = 0;
    assign adpcm_cs = 0;
    assign snd      = 0;
    assign game_led = 0;
`endif

jtvigil_sdram u_sdram(
    .rst        ( rst       ),
    .clk        ( clk       ),

    // Main CPU
    .main_cs    ( main_cs   ),
    .main_addr  ( main_addr ),
    .main_data  ( main_data ),
    .main_ok    ( main_ok   ),

    // Sound CPU
    .snd_addr   ( snd_addr  ),
    .snd_cs     ( snd_cs    ),
    .snd_data   ( snd_data  ),
    .snd_ok     ( snd_ok    ),

    // ADPCM ROM
    .adpcm_addr (adpcm_addr ),
    .adpcm_cs   (adpcm_cs   ),
    .adpcm_data (adpcm_data ),
    .adpcm_ok   (adpcm_ok   ),

    // Scroll
    .scr1_cs    ( scr1_cs   ),
    .scr1_ok    ( scr1_ok   ),
    .scr1_addr  ( scr1_addr ),
    .scr1_data  ( scr1_data ),

    .scr2_cs    ( scr2_cs   ),
    .scr2_ok    ( scr2_ok   ),
    .scr2_addr  ( scr2_addr ),
    .scr2_data  ( scr2_data ),

    // Sprite interface
    .obj_ok     ( obj_ok    ),
    .obj_cs     ( obj_cs    ),
    .obj_addr   ( obj_addr  ),
    .obj_data   ( obj_data  ),

    // Bank 0: allows R/W
    .ba0_addr    ( ba0_addr      ),
    .ba1_addr    ( ba1_addr      ),
    .ba2_addr    ( ba2_addr      ),
    .ba3_addr    ( ba3_addr      ),
    .ba_rd       ( ba_rd         ),
    .ba_ack      ( ba_ack        ),
    .ba_dst      ( ba_dst        ),
    .ba_dok      ( ba_dok        ),
    .ba_rdy      ( ba_rdy        ),

    .data_read   ( data_read     ),

    // ROM load
    .downloading ( downloading   ),
    .dwnld_busy  ( dwnld_busy    ),

    .ioctl_addr  ( ioctl_addr    ),
    .ioctl_dout  ( ioctl_dout    ),
    .ioctl_wr    ( ioctl_wr      ),
    .prog_addr   ( prog_addr     ),
    .prog_data   ( prog_data     ),
    .prog_mask   ( prog_mask     ),
    .prog_ba     ( prog_ba       ),
    .prog_we     ( prog_we       ),
    .prog_rd     ( prog_rd       ),
    .prog_ack    ( prog_ack      ),
    .prog_rdy    ( prog_rdy      )
);

endmodule
