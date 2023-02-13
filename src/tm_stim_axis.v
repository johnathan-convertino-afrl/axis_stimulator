//******************************************************************************
/// @file    tm_stim_axis.v
/// @author  JAY CONVERTINO
/// @date    2022.10.24
/// @brief   Generic AXIS test bench modules (stimulus) with verification.
/// @details All modules for AXIS test bench top are here. There will be loop of
///          tests the axis core must pass. In these tests is where the end user
///          must alter the checks if the input does not equal the output. As 
///          these were designed with a FIFO in mind.
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
  
//******************************************************************************
/// @brief Simulator core to read file data, and output it over master axis dut.
//******************************************************************************
module slave_axis_stimulus #(
    parameter BUS_WIDTH   = 1,          /**< bus width in bytes for data bus */
    parameter USER_WIDTH  = 1,          /**< user width in bits */
    parameter DEST_WIDTH  = 1,          /**< dest width in bits */
    parameter BYTE_SWAP   = 0,          /**< swap bytes fed to the DUT */
    parameter FILE        = "test.bin"  /**< input file name    */
  )
  (
    // master axis port
    input                           m_axis_aclk,  /**< master axis clock */
    input                           m_axis_arstn, /**< master negative reset */
    output reg                      m_axis_tvalid,/**< master data valid */
    input                           m_axis_tready,/**< master ready, is the next core ready */
    output      [(BUS_WIDTH*8)-1:0] m_axis_tdata, /**< master data */
    output reg  [BUS_WIDTH-1:0]     m_axis_tkeep, /**< master keep */
    output reg                      m_axis_tlast, /**< master last word of data */
    output reg  [USER_WIDTH-1:0]    m_axis_tuser, /**< master user port */
    output reg  [DEST_WIDTH-1:0]    m_axis_tdest  /**< master destination port */
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
      
      bytes_read = 0;
    // out of reset, run on posedge clock
    end else begin
      // first word fall through per axis
      
      if(r_b_fwft || m_axis_tready)
      begin
        bytes_read = $read_binary_file(FILE, r_m_axis_tdata);
        
        rr_m_axis_tdata <= r_m_axis_tdata;
        m_axis_tkeep    <= TKEEP_SHIFT >> (BUS_WIDTH - (bytes_read < 0 ? -1*bytes_read : bytes_read));
        m_axis_tvalid   <= 1'b1;
        m_axis_tlast    <= 1'b0;
        m_axis_tuser    <= 'h5;
        m_axis_tdest    <= 'h5;
        
        r_b_fwft <= 1'b0;
        
        if(bytes_read < 0)
        begin
          m_axis_tlast <= 1'b1;
        end
        
        if(bytes_read == 0)
        begin
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

//******************************************************************************
/// @brief  Simulator core to write file data, from input over slave axis dut.
///         This module will keep a constant ready to the dut.
//******************************************************************************
module master_axis_stimulus #(
    parameter BUS_WIDTH   = 1,        /**< bus width in bytes for data bus */
    parameter USER_WIDTH  = 1,        /**< user width in bits */
    parameter DEST_WIDTH  = 1,        /**< dest width in bits */
    parameter FILE        = "out.bin" /**< output file name   */
  )
  (
    // slave axis port
    input                       s_axis_aclk,  /**< slave axis clock */
    input                       s_axis_arstn, /**< slave negative reset */
    input                       s_axis_tvalid,/**< slave data valid */
    output reg                  s_axis_tready,/**< slave ready, are we ready kids? */
    input  [(BUS_WIDTH*8)-1:0]  s_axis_tdata, /**< slave data */
    input  [BUS_WIDTH-1:0]      s_axis_tkeep, /**< slave keep */
    input                       s_axis_tlast, /**< slave last word of data */
    input  [USER_WIDTH-1:0]     s_axis_tuser, /**< slave user port */
    input  [DEST_WIDTH-1:0]     s_axis_tdest  /**< slave destination port */
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
      s_axis_tready <= 1;

      if(s_axis_tvalid == 1)
      begin      
        num_wrote = $write_binary_file(FILE, s_axis_tdata);
        
        if(s_axis_tlast == 1)
        begin
          $finish;
        end
      end
    end
  end
  
endmodule

