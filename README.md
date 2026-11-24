#Parameterized Asynchronous FIFO & SystemVerilog CDC Verification with System Verilog Assertions(SVA)
#Overview
This project implements a synthesizable, parameterized Asynchronous FIFO ('DATA_WIDTH=8', 'DEPTH=16') for safe multi-bit data transfer with asynchronous clock and with  self-checking.

#Key Features
* RTL Design ('async_fifo.sv'):
  * Clock Domain Crossing (CDC): Binary-to-Gray code pointer conversion ('(bin >> 1) ^ bin') to eliminate multi-bit transition glitches.
  * Metastability Protection: Two-flip-flop ('2-FF') synchronizers transferring Gray-code pointers between 'wclk' and 'rclk' domains.
  * Full & Empty Detection: Accurate wrap-around flag generation using '(ADDR_WIDTH + 1)'-bit pointers.
* SystemVerilog Testbench ('async_fifo_tb.sv'):
  * Queue-Based Scoreboard: Dynamic SystemVerilog queue ('[$]) verifying strict First-In, First-Out data integrity with Pass/Fail reporting.

 Tools Used
* Language: SystemVerilog (IEEE 1800)
* Simulator: Verilator 5.044v ('--timing')
