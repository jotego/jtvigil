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

module jtvigil_main(
    input              clk,
    input              rst,
    input              cpu_cen,

    // BUS sharing
    output             main_rnw,
    output             [7:0] cpu_dout,

    // Video configuration
    output  reg        flip,
    input              LVBL,
    input              dip_pause,
    // Sound
    output  reg        latch_cs,
    // scroll
    output  reg [ 8:0] scr1pos,
    output  reg [10:0] scr2pos,
    output  reg [ 2:0] scr2col,
    // Object
    output  reg        obj_cs,
    // cabinet I/O
    input   [5:0]      joystick1,
    input   [5:0]      joystick2,
    input   [1:0]      start_button,
    input   [1:0]      coin_input,
    input              service,
    // DIP switches
    input              dip_flip,    // Not a DIP in the original board ;-)
    input    [7:0]     dipsw_a,
    input    [7:0]     dipsw_b,
    // ROM access
    output  reg        rom_cs,
    output      [17:0] rom_addr,
    input       [ 7:0] rom_data,
    input              rom_ok,
);

wire [15:0] A;
wire [ 7:0] ram_dout;
reg  [ 7:0] cpu_din;
reg  [ 2:0] bank;
reg         rst_n, ram_cs, dip1_cs, dip2_cs,
            in0_cs, in1_cs, in2_cs,
            latch_cs, out2_cs, bank_cs,
            scr1pos_cs, scr2pos_cs, scr2col_cs;
reg         flipr;
wire        rd_n, wr_n, mreq_n, iorq_n;
wire        int_n;

assign main_rnw = wr_n;
assign int_n    = LVBL | ~dip_pause;
assign rom_addr = A[15] ? { 1'b0, bank, rom_addr[13:0] } + 18'h8000 : { 3'd0, rom_addr[14:0] };

always @(posedge clk) rst_n <= ~rst;

always @* begin
    // Memory mapped
    rom_cs  = !mreq_n && ( !A[15] || A[15:14]==2'b10 ); // 16kB Banks x 8 = 128
    ram_cs  = !mreq_n && A[15:12]==4'he;
    scr_cs  = !mreq_n && A[15:12]==4'hd;
    pal_cs  = !mreq_n && A[15:11]==5'b11001; // C8
    obj_cs  = !mreq_n && A[15:11]==5'b11000; // C0 - to check
    // IO mapped
    in0_cs  = !iorq_n && !rd_n && A[2:0]==0;
    in1_cs  = !iorq_n && !rd_n && A[2:0]==1;
    in2_cs  = !iorq_n && !rd_n && A[2:0]==2;
    dip1_cs = !iorq_n && !rd_n && A[2:0]==3;
    dip2_cs = !iorq_n && !rd_n && A[2:0]==4;

    latch_cs = !iorq_n && !wr_n && A[2:0]==0;
    out2_cs  = !iorq_n && !wr_n && A[2:0]==1;
    bank_cs  = !iorq_n && !wr_n && A[2:0]==4;
    scr1pos_cs = !iorq_n && !wr_n && A[7] && A[2:1]==0;
    scr2pos_cs = !iorq_n && !wr_n && A[7] && A[2:1]==1;
    scr2col_cs = !iorq_n && !wr_n && A[7] && A[2:0]==4;
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        bank    <= 0;
        scr1pos <= 0;
        scr2pos <= 0;
        scr2col <= 0;
        FLIP    <= 0;
    end else begin
        flip <= flipr ^ dip2_cs[0];
        if( bank_cs    ) bank <= cpu_dout[2:0];
        if( out2_cs ) begin
            // COA1 COB1 ?
            flipr <= cpu_dout[0];
        end
        if( scr1pos_cs ) begin
            if( A[0] )
                scr1pos[10:8] <= cpu_dout[2:0];
            else
                scr1pos[ 7:0] <= cpu_dout;
        end
        if( scr2pos_cs ) begin
            if( A[0] )
                scr2pos[10:8] <= cpu_dout[2:0];
            else
                scr2pos[ 7:0] <= cpu_dout;
        end
        if( scr2col_cs ) begin
            // bit 6 ROME ? ROMF ?
            scr2col <= {cpu_dout[3], cpu_dout[1:0]};
        end
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        cpu_din <= 0;
    end else begin
        cpu_din <=
            rom_cs  ? rom_data :
            ram_cs  ? ram_dout :
            in0_cs  ? { 4'hf, coin_input[0], service, start_button } :
            in1_cs  ? { joystick1[5], 1'b1, joystick1[4], 1'b1, joystick1[3:0] } :
            in2_cs  ? { joystick2[5], 1'b1, joystick2[4], 1'b1, joystick2[3:0] } :
            dip1_cs ? dipsw_a  :
            dip2_cs ? dipsw_b  : 8'hff;
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
    .m1_n       (           ),
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


endmodule