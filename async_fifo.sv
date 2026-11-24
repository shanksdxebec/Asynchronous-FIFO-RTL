module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4
)(
  input wire wclk,
  input wire winc,
  input wire wrst_n,
  input wire[DATA_WIDTH-1:0] wdata,
  output reg wfull,
  input wire rclk,
  input wire rinc,
  input wire rrst_n,
  output wire[DATA_WIDTH-1:0] rdata,
  output reg rempty
);
  localparam DEPTH = 1<<ADDR_WIDTH;
  reg [DATA_WIDTH-1:0] mem[0:DEPTH-1];
  reg [ADDR_WIDTH:0] wbin, rbin;
  wire [ADDR_WIDTH:0] wbin_next, rbin_next;
  wire [ADDR_WIDTH:0] wgray_next, rgray_next;
  reg [ADDR_WIDTH:0] wptr, rptr;
  
  reg [ADDR_WIDTH:0] w1_rptr, w2_rptr;
  reg [ADDR_WIDTH:0] r1_wptr, r2_wptr;
  wire [ADDR_WIDTH-1:0] waddr = wbin[ADDR_WIDTH-1:0];
  wire [ADDR_WIDTH-1:0] raddr = rbin[ADDR_WIDTH-1:0];
  
  assign rdata = mem[raddr];
  
  always@(posedge wclk) begin
    if(winc && !wfull) begin
      mem[waddr]<= wdata;
    end
  end
  
  always@(posedge wclk or negedge wrst_n) begin
    if(!wrst_n) {w1_rptr, w2_rptr}<=0;
      else  {w2_rptr, w1_rptr}<= {w1_rptr, rptr};
  end
  
  always@(posedge rclk or negedge rrst_n) begin
    if(!rrst_n) {r1_wptr, r2_wptr}<=0;
    else {r2_wptr, r1_wptr}<= {r1_wptr, wptr};
  end
  
  assign wbin_next = wbin +{winc & ~wfull};
  assign wgray_next = (wbin_next>>1)^ wbin_next;
  wire wfull_val = (wgray_next == {~w2_rptr[ADDR_WIDTH: ADDR_WIDTH-1],w2_rptr[ADDR_WIDTH-2:0]});
                    
                    always@(posedge wclk or negedge wrst_n) begin
                      if(!wrst_n) begin
                        wbin<=0;
                        wptr<=0;
                        wfull<= 1'b0;
                      end else begin
                        wbin<= wbin_next;
                        wptr<= wgray_next;
                        wfull<= wfull_val;
                      end
                    end
                    
                    assign rbin_next = rbin+ {rinc & ~rempty};
                    assign rgray_next = (rbin_next>>1)^ rbin_next;
                    wire rempty_val = {rgray_next == r2_wptr};
                    
                    always@(posedge rclk or negedge rrst_n) begin
                      if(!rrst_n) begin
                        rbin<=0;
                        rptr<=0;
                        rempty<= 1'b1;
                      end else begin
                        rbin<=rbin_next;
                        rptr<=rgray_next;
                        rempty<= rempty_val;
                      end
                    end
                    endmodule
  
        
  
