/// @file    tb_axis.v
/// @author  JAY CONVERTINO
/// @date    2022.10.24
/// @brief   Generic AXIS test bench top with verification.
///
/// @LICENSE MIT
///  Copyright 2022 Jay Convertino
///
///  Permission is hereby granted, free of charge, to any person obtaining a copy
///  of this software and associated documentation files (the "Software"), to 
///  deal in the Software without restriction, including without limitation the
///  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
///  sell copies of the Software, and to permit persons to whom the Software is 
///  furnished to do so, subject to the following conditions:
///
///  The above copyright notice and this permission notice shall be included in 
///  all copies or substantial portions of the Software.
///
///  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
///  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
///  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
///  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
///  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
///  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
///  IN THE SOFTWARE.
//******************************************************************************

`timescale 1 ns/10 ps

module tb_axis #(
  parameter OUT_FILE_NAME = in.bin,
  parameter IN_FILE_NAME = out.bin,
  parameter RAND_READY = 0);
  //parameter or local param bus, user and dest width? and files as well? 
  
  localparam BUS_WIDTH  = 14;
  localparam USER_WIDTH = 1;
  localparam DEST_WIDTH = 1;
  
  wire                      tb_stim_clk;
  wire                      tb_stim_rstn;
  wire                      tb_stim_valid;
  wire [(BUS_WIDTH*8)-1:0]  tb_stim_data;
  wire [BUS_WIDTH-1:0]      tb_stim_keep;
  wire                      tb_stim_last;
  wire                      tb_stim_ready;
  wire [USER_WIDTH-1:0]     tb_stim_user;
  wire [DEST_WIDTH-1:0]     tb_stim_dest;
  wire                      tb_eof;
  
  clk_stimulus #(
    .CLOCKS(1), // # of clocks
    .CLOCK_BASE(1000000), // clock time base mhz
    .CLOCK_INC(1000), // clock time diff mhz
    .RESETS(1), // # of resets
    .RESET_BASE(2000), // time to stay in reset
    .RESET_INC(100) // time diff for other resets
  ) clk_stim (
    //clk out ... maybe a vector of clks with diff speeds.
    .clkv(tb_stim_clk),
    //rstn out ... maybe a vector of rsts with different off times
    .rstnv(tb_stim_rstn),
    .rstv()
  );
  
  slave_axis_stimulus #(
    .BUS_WIDTH(BUS_WIDTH),
    .USER_WIDTH(USER_WIDTH),
    .DEST_WIDTH(DEST_WIDTH),
    .FILE(IN_FILE_NAME)
  ) slave_axis_stim (
    // read
    .m_axis_aclk(tb_stim_clk),
    .m_axis_arstn(tb_stim_rstn),
    .m_axis_tvalid(tb_stim_valid),
    .m_axis_tready(tb_stim_ready),
    .m_axis_tdata(tb_stim_data),
    .m_axis_tkeep(tb_stim_keep),
    .m_axis_tlast(tb_stim_last),
    .m_axis_tuser(tb_stim_user),
    .m_axis_tdest(tb_stim_dest),
    .eof(tb_eof)
  );

  master_axis_stimulus #(
    .BUS_WIDTH(BUS_WIDTH),
    .USER_WIDTH(USER_WIDTH),
    .DEST_WIDTH(DEST_WIDTH),
    .RAND_READY(RAND_READY),
    .FILE(OUT_FILE_NAME)
  ) master_axis_stim (
    // write
    .s_axis_aclk(tb_stim_clk),
    .s_axis_arstn(tb_stim_rstn),
    .s_axis_tvalid(tb_stim_valid),
    .s_axis_tready(tb_stim_ready),
    .s_axis_tdata(tb_stim_data),
    .s_axis_tkeep(tb_stim_keep),
    .s_axis_tlast(tb_stim_last),
    .s_axis_tuser(tb_stim_user),
    .s_axis_tdest(tb_stim_dest),
    .eof(1'b0)
  );
  
  // vcd dump command
  initial begin
    $dumpfile ("tb_axis.vcd");
    $dumpvars (0, tb_axis);
    #1;
  end
  
endmodule

