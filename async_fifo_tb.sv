interface fifo_if #(parameter DATA_WIDTH = 8)(
  input logic wclk,
  input logic rclk
);
  logic wrst_n;
  logic winc;
  logic [DATA_WIDTH-1:0]wdata;
  logic wfull;
  logic rrst_n;
  logic rinc;
  logic [DATA_WIDTH-1:0]rdata;
  logic rempty;
endinterface

class fifo_transaction;
  logic [7:0] data;
  function void do_randomize();
    data = 8'($urandom_range(255, 0));
  endfunction
endclass

class fifo_scoreboard;
  logic [7:0]expected_q[$];
  int pass_count = 0;
  int fail_count = 0;
  
  function void record_write(logic [7:0]wdata);
    expected_q.push_back(wdata);
  endfunction
  
  function void check_read(logic [7:0]actualrdata);
    logic [7:0]exp_data;
    if(expected_q.size()==0) begin
      $display("SCOREBOARD FAIL.... DATA READ WHEN QUEUE IS EMPTY\n");
      fail_count++;
    end else begin
      exp_data = expected_q.pop_front();
      if (actualrdata == exp_data) begin
        pass_count++;
        $display("PASS Expected: 0x%h | Actual: 0x%h", exp_data, actualrdata);
      end else begin
        fail_count++;
        $error("FAIL Expected: 0x%h | Actual: 0x%h", exp_data, actualrdata);
      end
    end
  endfunction
  
  function void report();
    $display("\n==========================================");
    $display(" ASYNC FIFO VERIFICATION REPORT");
    $display(" TOTAL PASSED: %0d | TOTAL FAILED: %0d", pass_count, fail_count);
    $display("==========================================\n");
  endfunction
endclass

module testbench;
  logic wclk;
  logic rclk;
  
  int tick = 0;
  initial begin
    wclk = 1'b0;
    rclk = 1'b0;
    forever begin
      #5ns wclk = ~wclk;
      tick++;
      if(tick%3 == 0) begin
        rclk = ~rclk;
      end
    end
  end
   
  fifo_if #(8) intf(wclk, rclk);
  
  async_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) u_dut (  .wclk(intf.wclk),.wrst_n(intf.wrst_n),.winc(intf.winc),.wdata(intf.wdata),.wfull(intf.wfull),.rclk(intf.rclk),.rrst_n(intf.rrst_n),.rinc(intf.rinc), .rdata(intf.rdata), .rempty(intf.rempty)
);
  fifo_scoreboard sb;
  
   task automatic run_writes(int num_writes);
        fifo_transaction tr;
        int writes_done = 0;
        while (writes_done < num_writes) begin
            @(posedge wclk);
            #1ps;
            if (!intf.wfull) begin
                tr = new();
                tr.do_randomize();
                intf.winc  = 1'b1;
                intf.wdata = tr.data;
                sb.record_write(tr.data);
                $display("[TIME: %0t] [WRITE #%0d] Pushed: 0x%h", $time, writes_done + 1, tr.data);
                writes_done++;
            end else begin
                intf.winc = 1'b0;
                $display("[TIME: %0t] [WRITE STALL] FIFO is FULL! Waiting...", $time);
            end
        end
        @(posedge wclk);
        #1ps;
        intf.winc = 1'b0;
    endtask
  
   task automatic run_reads(int num_reads);
     int reads_done = 0;
     while (reads_done < num_reads) begin
       @(posedge rclk);
       #1ps;
       if (!intf.rempty) begin
         intf.rinc = 1'b1;   
         $display("[TIME: %0t] [READ #%0d] Popped: 0x%h", $time, reads_done + 1, intf.rdata);
         sb.check_read(intf.rdata);
         reads_done++;
       end else begin
         intf.rinc = 1'b0;
         $display("[TIME: %0t] [READ STALL] FIFO is EMPTY! Waiting...", $time);
       end
     end
     @(posedge rclk);
     #1ps;
     intf.rinc = 1'b0;
   endtask
  
  initial begin
    sb = new();
    intf.wrst_n = 1'b0;
    intf.rrst_n = 1'b0;
    intf.winc = 1'b0;
    intf.rinc = 1'b0;
    intf.wdata = 8'h00;
    
    #30ns;
    intf.wrst_n = 1;
    intf.rrst_n = 1;
    #20ns;
    
    fork
      run_writes(20);
      begin
        #150ns;
        run_reads(20);
      end
    join
    
    #100ns;
    sb.report();
    $finish;
  end
  
   initial begin
        #15000ns;
        $display("[ERROR] Simulation Timeout!");
        $finish;
   end
  property p_no_write_when_full;
    @(posedge wclk) disable iff (!intf.wrst_n)
    (intf.winc && intf.wfull) |=> $stable(u_dut.wbin);
  endproperty
  assert property (p_no_write_when_full)
    else $error("[SVA FAIL] Write pointer incremented while FIFO was full");
    
    property p_no_read_when_empty;
      @(posedge rclk) disable iff (!intf.rrst_n)
      (intf.rinc && intf.rempty) |=> $stable(u_dut.rbin);
    endproperty
    assert property (p_no_read_when_empty)
      else $error("[SVA FAIL] Read pointer incremented while FIFO was empty");
      
      property p_never_full_and_empty;
        @(posedge wclk) disable iff (!intf.wrst_n || !intf.rrst_n)
        !(intf.wfull && intf.rempty);
      endproperty
      assert property (p_never_full_and_empty)
        else $error("[SVA FAIL] Illegal state: FIFO is both full and empty");
        
        property p_reset_wfull;
          @(posedge wclk)
          (!intf.wrst_n) -> (intf.wfull == 1'b0);
        endproperty
        assert property (p_reset_wfull)
          else $error("[SVA FAIL] wfull not 0 when reset");  
endmodule

    
    
    
  
    
