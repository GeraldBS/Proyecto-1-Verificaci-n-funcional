//////////////////////////////////////////////////////////////////////
// prueba_driver: prueba dirigida del driver, sin generator         //
//////////////////////////////////////////////////////////////////////
// Mete paquetes a mano en el mailbox del padre y revisa que los
// reparta bien, que salgan en orden y que t_envio quede marcado.
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

  // cuenta lo que llega a cada terminal
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
  int esp_rcbd [drvrs];   // cuantos deberia recibir cada terminal

  // paquete armado a mano, sin randomize
  // OJO: la funcion va automatic. Sin eso "packet p = new()" se
  // ejecuta una sola vez al inicio y todas las llamadas devuelven
  // el mismo objeto.
  function automatic packet nuevo(int org, int dst, int pay, int rtrd, tipo_pckg tp);
    packet p;
    p = new();
    p.origen  = org[7:0];
    p.destino = dst[7:0];
    p.payload = pay;
    p.retardo = rtrd;
    p.tipo    = tp;
    p.id      = esperados + 1;

    // quien deberia recibirlo
    for (int i = 0; i < drvrs; i++) begin
      if (tp == envio_broadcast) begin
        if (i != org) esp_rcbd[i]++;
      end
      else if (i == dst && dst != org) esp_rcbd[i]++;
    end
    return p;
  endfunction

  initial begin
    packet p;

    for (int i = 0; i < drvrs; i++) begin
      recibidos[i] = 0;
      esp_rcbd[i]  = 0;
    end

    gen_agnt_mbx = new();
    drv_chkr_mbx = new();
    padre = new();
    padre.vif          = _if;
    padre.gen_agnt_mbx = gen_agnt_mbx;
    padre.drv_chkr_mbx = drv_chkr_mbx;

    fork padre.run(); join_none

    // tres seguidos del terminal 0 para ver el orden de la cola
    gen_agnt_mbx.put(nuevo(0, 1, 'h11, 0, envio_normal));
    gen_agnt_mbx.put(nuevo(0, 2, 'h22, 0, envio_normal));
    gen_agnt_mbx.put(nuevo(0, 3, 'h33, 0, envio_normal));
    esperados = 3;

    // uno con retardo desde otro terminal
    gen_agnt_mbx.put(nuevo(drvrs-1, 0, 'h44, 5, envio_normal));
    esperados = 4;

    // broadcast, lo reciben drvrs-1
    gen_agnt_mbx.put(nuevo(1, `BROADCAST, 'h55, 0, envio_broadcast));
    esperados = 5;

    // espera a que salga todo
    repeat (10 * (pckg_sz + 2*drvrs + 20)) @(posedge clk);

    $display("---- resumen ----");
    $display("paquetes repartidos por el padre : %0d", padre.repartidos);
    $display("paquetes que tomo el DUT (pop)   : %0d", padre.total_enviados());
    for (int i = 0; i < drvrs; i++) begin
      $display("terminal %0d recibio %0d, esperado %0d", i, recibidos[i], esp_rcbd[i]);
      if (recibidos[i] != esp_rcbd[i]) begin
        errores++;
        $display("ERROR: terminal %0d recibio %0d y se esperaban %0d",
                 i, recibidos[i], esp_rcbd[i]);
      end
    end

    if (padre.repartidos != esperados) begin
      errores++;
      $display("ERROR: el padre repartio %0d y se esperaban %0d", padre.repartidos, esperados);
    end
    if (padre.total_enviados() != esperados) begin
      errores++;
      $display("ERROR: el DUT tomo %0d paquetes y se esperaban %0d", padre.total_enviados(), esperados);
    end

    // revisa que llegaran al checker con t_envio
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
