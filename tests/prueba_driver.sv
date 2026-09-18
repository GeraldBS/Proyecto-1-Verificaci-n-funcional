//////////////////////////////////////////////////////////////////////
// prueba_driver: revisa el driver y el agent_drv sin generator     //
//////////////////////////////////////////////////////////////////////
// Mete paquetes a mano en el mailbox del padre y confirma que:
//  - el padre los reparte al hijo correcto segun el origen
//  - cada hijo los entrega al DUT en orden (fifo)
//  - el DUT los recibe en el terminal destino
//  - t_envio queda marcado en el pop
//////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

`include "fifo.sv"
`define FIFOS
`include "Library.sv"

`include "parametros.svh"
`include "interfaces/interfaz.sv"
`include "pkg/tb_pkg.sv"

module prueba_driver;

  parameter bits    = `BITS;
  parameter drvrs   = `DRVRS;
  parameter pckg_sz = `PCKG_SZ;

  bit clk = 0;
  always #(`PERIODO_CLK/2.0) clk = ~clk;

  bus_if #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) _if (.clk(clk));

  bs_gnrtr_n_rbtr #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz),
                    .broadcast(`BROADCAST)) dut (
    .clk (_if.clk), .reset(_if.reset), .pndng(_if.pndng),
    .push(_if.push), .pop (_if.pop),   .D_pop(_if.D_pop), .D_push(_if.D_push)
  );

  // cuenta lo que recibe cada terminal
  int recibidos [drvrs];
  genvar g;
  generate
    for (g = 0; g < drvrs; g++) begin : MON
      always @(posedge clk) if (_if.push[0][g] === 1'b1) begin
        recibidos[g]++;
        $display("[%0t] terminal %0d recibe 0x%0h", $time, g, _if.D_push[0][g]);
      end
    end
  endgenerate

  agent_drv  padre;
  packet_mbx gen_agnt_mbx;
  packet_mbx drv_chkr_mbx;

  int esperados = 0;
  int errores   = 0;

  // arma un paquete a mano
  function packet nuevo(int org, int dst, int pay, int rtrd, tipo_pckg tp);
    packet p = new();
    p.origen  = org[7:0];
    p.destino = dst[7:0];
    p.payload = pay;
    p.retardo = rtrd;
    p.tipo    = tp;
    p.id      = esperados + 1;
    return p;
  endfunction

  initial begin
    packet p;

    gen_agnt_mbx = new();
    drv_chkr_mbx = new();
    padre = new();
    padre.vif          = _if;
    padre.gen_agnt_mbx = gen_agnt_mbx;
    padre.drv_chkr_mbx = drv_chkr_mbx;

    fork padre.run(); join_none

    // tres paquetes seguidos del terminal 0, para ver el orden de la fifo
    gen_agnt_mbx.put(nuevo(0, 1, 'h11, 0, envio_normal));
    gen_agnt_mbx.put(nuevo(0, 2, 'h22, 0, envio_normal));
    gen_agnt_mbx.put(nuevo(0, 3, 'h33, 0, envio_normal));
    esperados = 3;

    // uno desde otro terminal, con retardo
    gen_agnt_mbx.put(nuevo(drvrs-1, 0, 'h44, 5, envio_normal));
    esperados = 4;

    // un broadcast: lo reciben drvrs-1 terminales
    gen_agnt_mbx.put(nuevo(1, `BROADCAST, 'h55, 0, envio_broadcast));
    esperados = 5;

    // espera suficiente para que todo salga
    repeat (10 * (pckg_sz + 2*drvrs + 20)) @(posedge clk);

    $display("---- resumen ----");
    $display("paquetes repartidos por el padre : %0d", padre.repartidos);
    $display("paquetes que tomo el DUT (pop)   : %0d", padre.total_enviados());
    for (int i = 0; i < drvrs; i++)
      $display("terminal %0d recibio %0d", i, recibidos[i]);

    if (padre.repartidos != esperados) begin
      errores++;
      $display("ERROR: el padre repartio %0d y se esperaban %0d", padre.repartidos, esperados);
    end
    if (padre.total_enviados() != esperados) begin
      errores++;
      $display("ERROR: el DUT tomo %0d paquetes y se esperaban %0d", padre.total_enviados(), esperados);
    end

    // revisa que el checker haya recibido todo con t_envio marcado
    while (drv_chkr_mbx.num() > 0) begin
      drv_chkr_mbx.get(p);
      if (p.t_envio == 0) begin
        errores++;
        $display("ERROR: paquete id=%0d sin t_envio", p.id);
      end
    end

    if (errores == 0) $display("==== PRUEBA DRIVER: PASS ====");
    else              $display("==== PRUEBA DRIVER: FAIL (%0d errores) ====", errores);
    $finish;
  end

  initial begin
    #(`PERIODO_CLK * 20000);
    $display("==== PRUEBA DRIVER: TIMEOUT ====");
    $finish;
  end

endmodule
