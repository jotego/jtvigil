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

module jtvigil_snd(
    input                clk,
    input                rst,
    input                cpu_cen,
    input                fm_cen,

    // From main
    input         [ 7:0] main_dout,
    input                latch_wr,

    // ROM access
    output    reg        rom_cs,
    output        [15:0] rom_addr,
    input         [ 7:0] rom_data,
    input                rom_ok,

    output    reg        pcm_cs,
    output    reg [15:0] pcm_addr,
    input         [ 7:0] pcm_data,
    input                pcm_ok,

    output signed [15:0] snd,
    output               sample,
    output               peak
);

localparam [7:0] FM_GAIN  = 8'h08,
                 PCM_GAIN = 8'h08;

wire [15:0] A;
wire [ 7:0] ram_dout, fm_dout, cpu_dout;
reg  [ 7:0] cpu_din, latch;
reg  [ 2:0] bank;
reg         rst_n, ram_cs,  cntcs_l,
            fm_cs, latch_cs, irq_clr,
            hi_cs, lo_cs, cnt_cs, pcm_rd;
wire        rd_n, wr_n, mreq_n, iorq_n;
reg         int_n;
wire        fm_intn;

wire signed [15:0] left, right;

assign pcm_cs   = 1;
assign rom_addr = A;

always @(posedge clk) rst_n <= ~rst;

always @* begin
    // Memory mapped
    rom_cs  = !mreq_n && A[15:14]<2'b10;
    ram_cs  = !mreq_n && A[15:12]==4'hf;
    // IO mapped
    fm_cs   = !iorq_n && !rd_n && !A[7];
    latch_cs= !iorq_n && !rd_n &&  A[7] && A[2:0]==0;
    irq_clr = !iorq_n && !rd_n &&  A[7] && A[2:0]==3;
    // PCM control
    lo_cs   = !iorq_n && !wr_n &&  A[7] && A[2:0]==0;
    hi_cs   = !iorq_n && !wr_n &&  A[7] && A[2:0]==1;
    cnt_cs  = !iorq_n && !wr_n &&  A[7] && A[2:0]==2;
    pcm_rd  = !iorq_n && !rd_n &&  A[7] && A[2:0]==4;
end

// latch from main CPU
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        latch <= 0;
        int_n <= 1;
    end else begin
        if( latch_wr ) begin
            latch <= main_dout;
            int_n <= 0;
        end
        if( irq_clr ) int_n <= 1;
    end
end

// PCM controller
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        pcm_addr <= 16'd0;
        cntcs_l  <= 0;
    end else begin
        cntcs_l <= cnt_cs;
        if( hi_cs ) pcm_addr[15:8] <= cpu_dout;
        if( lo_cs ) pcm_addr[ 7:0] <= cpu_dout;
        if( cnt_cs && !cntcs_l ) pcm_addr <= pcm_addr + 16'd1;
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        cpu_din <= 0;
    end else begin
        cpu_din <=
            rom_cs  ? rom_data :
            ram_cs  ? ram_dout :
            pcm_rd  ? pcm_data :
            fm_cs   ? fm_dout  : 8'hff;
    end
end

jtframe_sysz80 #(
    .RAM_AW     ( 12        ),
    .CLR_INT    ( 1         ),
) u_cpu(
    .rst_n      ( rst_n     ),
    .clk,       ( clk       )
    .cen,       ( cpu_cen   )
    .cpu_cen    (           ),
    .int_n      ( int_n     ),
    .nmi_n      ( 1'b1      ),
    .busrq_n    ( 1'b1      ),
    .m1_n       ( fm_intn   ),
    .mreq_n     ( mreq_n    ),
    .iorq_n     ( iorq_n    ),
    .rd_n       ( rd_n      ),
    .wr_n       ( wr_n      ),
    .rfsh_n     (           ),
    .halt_n     (           ),
    .busak_n    (           ),
    .A          ( A         ),
    .cpu_din    ( cpu_din   ),
    .cpu_dout   ( cpu_dout  ),
    .ram_dout   ( ram_dout  ),
    // ROM access
    .ram_cs     ( ram_cs    ),
    .rom_cs     ( rom_cs    ),
    .rom_ok     ( rom_ok    )
);

jt51 u_jt51 (
    .rst     ( rst        ),
    .clk     ( clk        ),
    .cen     ( cpu_cen    ),
    .cen_p1  ( fm_cen     ),
    .cs_n    ( !fm_cs     ),
    .wr_n    ( wr_n       ),
    .a0      ( A[0]       ),
    .din     ( cpu_dout   ),
    .dout    ( fm_dout    ),
    .ct1     (            ),
    .ct2     (            ),
    .irq_n   ( fm_intn    ),
    .sample  ( sample     ),
    .left    (            ),
    .right   (            ),
    .xleft   ( left       ),
    .xright  ( right      )
);


jtframe_mixer #(.W2(8)) u_mixer (
    .rst   ( rst        ),
    .clk   ( clk        ),
    .cen   ( fm_cen     ),
    .ch0   ( left       ),
    .ch1   ( right      ),
    .ch2   ( pcm_data   ),
    .ch3   ( 16'd0      ),
    .gain0 ( FM_GAIN    ),
    .gain1 ( FM_GAIN    ),
    .gain2 ( PCM_GAIN   ),
    .gain3 ( 8'h00      ),
    .mixed ( snd        ),
    .peak  ( peak       )
);


endmodule