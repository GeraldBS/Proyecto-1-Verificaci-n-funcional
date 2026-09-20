//////////////////////////////////////////////////////////////////////
// tb_top: modulo de arriba, conecta el DUT con la interfaz         //
//////////////////////////////////////////////////////////////////////
// Se compila este archivo, el resto entra por los include.
//   vcs ... +incdir+rtl +incdir+tb +incdir+tests tb/top/tb_top.sv
//////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

// FIFOS se define para que Library.sv no busque ../FIFO_Latches/fifo.sv
`include "fifo.sv"
`define FIFOS
`include "Library.sv"

`include "parametros.svh"
`include "interfaces/interfaz.sv"
`include "pkg/tb_pkg.sv"
`include "test_general.sv"

module tb_top;

  parameter bits    = `BITS;
  parameter drvrs   = `DRVRS;
  parameter pckg_sz = `PCKG_SZ;

  bit clk = 0;
  always #(`PERIODO_CLK/2.0) clk = ~clk;

  bus_if #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) _if (.clk(clk));

  bs_gnrtr_n_rbtr #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz),
                    .broadcast(`BROADCAST)) dut (
    .clk   (_if.clk),
    .reset (_if.reset),
    .pndng (_if.pndng),
    .push  (_if.push),
    .pop   (_if.pop),
    .D_pop (_if.D_pop),
    .D_push(_if.D_push)
  );

  test t0;

  initial begin
    // los tiempos se imprimen en ns; sin esto %t sale en ps
    $timeformat(-9, 0, " ns", 10);
    $display("==== tb_top: PCKG_SZ=%0d DRVRS=%0d ====", pckg_sz, drvrs);
    t0 = new();
    t0.vif = _if;
    t0.run();
    $display("==== fin de la prueba ====");
    $finish;
  end

  // por si algo se queda trabado
  initial begin
    #(`PERIODO_CLK * 500000);
    $display("==== TIMEOUT ====");
    $finish;
  end

endmodule
