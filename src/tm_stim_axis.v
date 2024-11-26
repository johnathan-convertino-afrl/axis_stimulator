//******************************************************************************
//  file:     tm_stim_axis.v
//
//  author:   JAY CONVERTINO
//
//  date:     2022/10/24
//
//  about:    Brief
//  All modules for AXIS test bench top are here. There will be loop of
//  tests the axis core must pass. In these tests is where the end user
//  must alter the checks if the input does not equal the output. As
//  these were designed with a FIFO in mind.
//
//  license: License MIT
//  Copyright 2022 Jay Convertino
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//******************************************************************************

`timescale 1 ns/10 ps

/*
 * Module: slave_axis_stimulus
 *
 * Simulator core to read file data, and output it over master axis dut.
 *
 * Parameters:
 *
 * BUS_WIDTH    - bus width in bytes for data bus
 * USER_WIDTH   - user width in bits
 * DEST_WIDTH   - dest width in bits
 * BYTE_SWAP    - swap bytes fed to the DUT
 * FILE         - input file name
 *
 * Ports:
 *
 * m_axis_aclk    - master axis clock
 * m_axis_arstn   - master axis negative reset
 * m_axis_tvalid  - master axis data valid active high
 * m_axis_tready  - master axis, is the input device ready?
 * m_axis_tdata   - master axis data input.
 * m_axis_tkeep   - master axis byte indicator
 * m_axis_tlast   - master axis data is last word
 * m_axis_tuser   - master axis user defined
 * m_axis_tdest   - master axis desitination
 * eof            - end of input file has been reached.
 */
module slave_axis_stimulus #(
    parameter BUS_WIDTH   = 1,
    parameter USER_WIDTH  = 1,
    parameter DEST_WIDTH  = 1,
    parameter BYTE_SWAP   = 0,
    parameter FILE        = "test.bin"
  )
  (
    input                           m_axis_aclk,
    input                           m_axis_arstn,
    output reg                      m_axis_tvalid,
    input                           m_axis_tready,
    output      [(BUS_WIDTH*8)-1:0] m_axis_tdata,
    output reg  [BUS_WIDTH-1:0]     m_axis_tkeep,
    output reg                      m_axis_tlast,
    output reg  [USER_WIDTH-1:0]    m_axis_tuser,
    output reg  [DEST_WIDTH-1:0]    m_axis_tdest,
    output reg                      eof
  );
  
  // local parameters
  /// @brief ones for tkeep
  localparam TKEEP_SHIFT = {BUS_WIDTH{1'b1}};
  
  reg r_b_fwft;
  
  // axis data register for read in data
  reg [(BUS_WIDTH*8)-1:0] r_m_axis_tdata;
  // axis data register for output data
  reg [(BUS_WIDTH*8)-1:0] rr_m_axis_tdata;
  
  
  // local variables
  integer bytes_read;
  
  // generate variables
  genvar gen_index;
  
  //****************************************************************************
  /// @brief  generate block to change endianness of input read use this if data
  ///         is in an order you do not expect.
  //****************************************************************************
  generate
    if(BYTE_SWAP == 1) begin
      for(gen_index = 0; gen_index < BUS_WIDTH; gen_index = gen_index + 1) begin
        assign m_axis_tdata[8*gen_index +: 8] = rr_m_axis_tdata[((BUS_WIDTH*8)-(gen_index*8)-1) -:8];
      end
    end else begin
      assign m_axis_tdata = rr_m_axis_tdata;
    end
  endgenerate
  
  //****************************************************************************
  /// @brief block for master axis output data
  //****************************************************************************
  // positive edge clock
  always @(posedge m_axis_aclk) begin
    // reset signal on negative edge
    if(m_axis_arstn == 1'b0) begin
      // reset signals
      m_axis_tvalid <= 0;
      m_axis_tkeep  <= 0;
      m_axis_tlast  <= 0;
      m_axis_tuser  <= 0;
      m_axis_tdest  <= 0;
      
      r_m_axis_tdata  <= 0;
      rr_m_axis_tdata <= 0;
      
      r_b_fwft <= 1'b1;
      
      eof <= 1'b0;
      
      bytes_read = 0;
    // out of reset, run on posedge clock
    end else begin
      eof <= eof;
      // first word fall through per axis
      
      if(r_b_fwft || m_axis_tready) begin
        bytes_read = $read_binary_file(FILE, r_m_axis_tdata);
        
        rr_m_axis_tdata <= r_m_axis_tdata;
        m_axis_tkeep    <= TKEEP_SHIFT >> (BUS_WIDTH - (bytes_read < 0 ? -1*bytes_read : bytes_read));
        m_axis_tvalid   <= 1'b1;
        m_axis_tlast    <= 1'b0;
        m_axis_tuser    <= 'h5;
        m_axis_tdest    <= 'h5;
        
        r_b_fwft <= 1'b0;
        
        if(bytes_read < 0) begin
          eof          <= 1'b1;
          m_axis_tlast <= 1'b1;
        end
        
        if(bytes_read == 0) begin
          rr_m_axis_tdata <= 0;
          m_axis_tkeep    <= 0;
          m_axis_tvalid   <= 1'b0;
          m_axis_tlast    <= 1'b0;
          m_axis_tuser    <= 0;
          m_axis_tdest    <= 0;
        end
      end
    end
  end
  
endmodule

/*
 * Module: master_axis_stimulus
 *
 * Simulator core to write file data, from input over slave axis dut. This module will keep a constant ready to the dut.
 *
 * Parameters:
 *
 * BUS_WIDTH    - bus width in bytes for data bus
 * USER_WIDTH   - user width in bits
 * DEST_WIDTH   - dest width in bits
 * RAND_READY   - random ready if set anything other than 0
 * FILE         - output file name
 *
 * Ports:
 *
 * s_axis_aclk    - slave axis clock
 * s_axis_arstn   - slave axis negative reset
 * s_axis_tvalid  - slave data valid
 * s_axis_tready  - slave ready
 * s_axis_tdata   - slave data
 * s_axis_tkeep   - slave keep
 * s_axis_tlast   - slave last word of data
 * s_axis_tuser   - slave user port
 * s_axis_tdest   - slave destination port
 * eof            - end of file will trigger $finish to end sim
 */
module master_axis_stimulus #(
    parameter BUS_WIDTH   = 1,
    parameter USER_WIDTH  = 1,
    parameter DEST_WIDTH  = 1,
    parameter RAND_READY  = 0,
    parameter FILE        = "out.bin"
  )
  (
    input                       s_axis_aclk,
    input                       s_axis_arstn,
    input                       s_axis_tvalid,
    output reg                  s_axis_tready,
    input  [(BUS_WIDTH*8)-1:0]  s_axis_tdata,
    input  [BUS_WIDTH-1:0]      s_axis_tkeep,
    input                       s_axis_tlast,
    input  [USER_WIDTH-1:0]     s_axis_tuser,
    input  [DEST_WIDTH-1:0]     s_axis_tdest,
    input                       eof
  );
  
  integer num_wrote = 0;
  
  //****************************************************************************
  /// @brief block for slave axis input data
  //****************************************************************************
  // positive edge clock
  always @(posedge s_axis_aclk) begin
    // reset signal on negative edge
    if(s_axis_arstn == 1'b0) begin
      // reset signals
      s_axis_tready <= 0;
      
      num_wrote <= 0;
    // out of reset, run on posedge clock
    end else begin
      s_axis_tready <= (RAND_READY != 0 ? $random%2 : 1);
      
      if((s_axis_tvalid == 1'b1) && (s_axis_tready == 1'b1)) begin      
        num_wrote = $write_binary_file(FILE, s_axis_tdata);
      end
      
      if((((s_axis_tlast == 1'b1) && (s_axis_tvalid == 1'b1)) || (eof == 1'b1)) && (s_axis_tready == 1'b1))begin
        $finish();
      end
    end
  end
  
endmodule

