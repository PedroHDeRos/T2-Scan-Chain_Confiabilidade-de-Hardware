`timescale 1ns/1ps

module stream_merge #(
  parameter int DATA_W = 32,
  parameter int DEPTH = 8,
  parameter int WMAX   = 7
)(
  input logic                          clk,
  input logic                          rst_n,
  input logic [$clog2(DEPTH+1)-1:0]    cfg_af_thresh,
  input logic [$clog2(WMAX+1)-1:0]     cfg_weight0,
  input logic [$clog2(WMAX+1)-1:0]     cfg_weight1,
  input logic                          in0_valid,
  input logic [DATA_W-1:0]             in0_data,
  input logic                          in0_sop,
  input logic                          in0_eop,
  output logic                         in0_ready,
  input logic                          in1_valid,
  input logic [DATA_W-1:0]             in1_data,
  input logic                          in1_sop,
  input logic                          in1_eop,
  output logic                         in1_ready,
  output logic                         out_valid,
  output logic [DATA_W-1:0]            out_data,
  output logic                         out_src,
  output logic                         out_sop,
  output logic                         out_eop,
  input logic                          out_ready,
  output logic [$clog2(DEPTH+1)-1:0]   occupancy,
  output logic                         empty,
  output logic                         full,
  output logic                         almost_full
);

  localparam int PTR_W = $clog2(DEPTH);
  localparam int CNT_W = $clog2(DEPTH+1);
  localparam int WT_W  = $clog2(WMAX+1);

  logic [DATA_W-1:0] mem_data [DEPTH];
  logic              mem_src [DEPTH];
  logic              mem_sop [DEPTH];
  logic              mem_eop [DEPTH];
  logic [PTR_W-1:0] wr_ptr, rd_ptr;
  logic [CNT_W-1:0] occ;

  logic              locked;
  logic              lock_src;
  logic [WT_W-1:0]   credit0;
  logic [WT_W-1:0]   credit1;

  logic off0, off1;
  logic recharge;
  logic [WT_W-1:0] ec0, ec1;
  logic elig0, elig1;
  logic serve;
  logic serve_ok;
  logic push, pop;
  logic acc_sop, acc_eop;

  assign off0 = in0_valid;
  assign off1 = in1_valid;

  assign recharge = !locked && (off0 || off1) &&
                    !((off0 && (credit0 != '0)) ||
                      (off1 && (credit1 != '0)));

  assign ec0 = recharge ? cfg_weight0 : credit0;
  assign ec1 = recharge ? cfg_weight1 : credit1;
  assign elig0 = off0 && (ec0 != '0);
  assign elig1 = off1 && (ec1 != '0);

  always_comb begin
    if (locked)              serve = lock_src;
    else if (elig0 && elig1) serve = 1'b0;
    else if (elig1)          serve = 1'b1;
    else                     serve = 1'b0;
  end

  assign serve_ok = !full && (locked ? 1'b1 : (serve ? elig1 : elig0));

  assign in0_ready = rst_n && serve_ok && (serve == 1'b0);
  assign in1_ready = rst_n && serve_ok && (serve == 1'b1);

  assign push = (in0_valid && in0_ready) || (in1_valid && in1_ready);
  assign pop = out_valid && out_ready;

  assign acc_sop = serve ? in1_sop : in0_sop;
  assign acc_eop = serve ? in1_eop : in0_eop;

  assign full        = (occ == CNT_W'(DEPTH));
  assign empty       = (occ == '0);
  assign almost_full = (occ >= cfg_af_thresh);
  assign occupancy   = rst_n ? occ : '0;

  assign out_valid = rst_n && !empty;
  assign out_data = mem_data[rd_ptr];
  assign out_src   = mem_src[rd_ptr];
  assign out_sop   = mem_sop[rd_ptr];
  assign out_eop   = mem_eop[rd_ptr];

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      wr_ptr   <= '0;
      rd_ptr   <= '0;
      occ      <= '0;
      locked   <= 1'b0;
      lock_src <= 1'b0;
      credit0 <= '0;
      credit1 <= '0;
    end
    else begin
      if (push) begin
        mem_data[wr_ptr] <= serve ? in1_data : in0_data;
        mem_src [wr_ptr] <= serve;
        mem_sop [wr_ptr] <= acc_sop;
        mem_eop [wr_ptr] <= acc_eop;
        wr_ptr           <= wr_ptr + 1'b1;

        locked   <= ~acc_eop;
        lock_src <= serve;

        if (!locked) begin
          credit0 <= (serve == 1'b0) ? (ec0 - 1'b1) : ec0;
          credit1 <= (serve == 1'b1) ? (ec1 - 1'b1) : ec1;
        end
      end

      if (pop) begin
        rd_ptr <= rd_ptr + 1'b1;
      end

      case ({push, pop})
        2'b10:   occ <= occ + 1'b1;
        2'b01:   occ <= occ - 1'b1;
        default: occ <= occ;
      endcase
    end
  end
endmodule
