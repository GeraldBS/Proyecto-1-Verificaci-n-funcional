//////////////////////////////////////////////////////////////////////
// prueba_monitor: prueba dirigida del monitor (agent_mon)          //
//////////////////////////////////////////////////////////////////////
// Usa el agent_drv real (igual que prueba_driver.sv) para meter los
// mismos 5 paquetes en el DUT, pero esta vez el que revisa lo que
// sale es el agent_mon real, no un "MON" armado a mano.
//
// Se comparan los mismos paquetes que prueba_driver.sv a proposito:
// si esta prueba y esa coinciden en cuantos le llegan a cada
// terminal, es una señal de que el monitor esta viendo lo mismo que
// el DUT en verdad entrego.
//
// Ademas de contar, aqui se revisa CONTENIDO: que cada pckg_mon que
// junta el agent_mon traiga el destino y el payload que se esperaba
// para esa terminal (sin importar el orden de llegada entre
// terminales distintas), y que t_recibido quede marcado.
//////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

`include "fifo.sv"
`define FIFOS
`include "Library.sv"

`include "parametros.svh"
`include "interfaces/interfaz.sv"
`include "pkg/tb_pkg.sv"

module prueba_monitor;

  parameter bits    = `BITS;
  parameter drvrs   = `DRVRS;
  parameter pckg_sz = `PCKG_SZ;

  localparam int ANCHO_PAYLOAD = pckg_sz - `ANCHO_DIR;

  bit clk = 0;
  always #(`PERIODO_CLK/2.0) clk = ~clk;

  bus_if #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) _if (.clk(clk));

  bs_gnrtr_n_rbtr #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz),
                    .broadcast(`BROADCAST)) dut (
    .clk (_if.clk), .reset(_if.reset), .pndng(_if.pndng),
    .push(_if.push), .pop (_if.pop),   .D_pop(_if.D_pop), .D_push(_if.D_push)
  );

  agent_drv    padre_drv;
  agent_mon    padre_mon;
  packet_mbx   gen_agnt_mbx;
  packet_mbx   drv_chkr_mbx;
  pckg_mon_mbx mon_chkr_mbx;

  int esperados = 0;
  int errores   = 0;
  int esp_rcbd [drvrs];   // cuantos deberia recibir cada terminal

  // lo que deberia ver cada terminal, para revisar contenido y no solo conteo
  bit [`ANCHO_DIR-1:0]   esp_destino [drvrs][$];
  bit [ANCHO_PAYLOAD-1:0] esp_payload[drvrs][$];

  // paquete armado a mano, igual que en prueba_driver.sv
  // (automatic por lo mismo: sin eso "p = new()" se ejecuta una sola
  // vez y todas las llamadas devuelven el mismo objeto)
  function automatic packet nuevo(int org, int dst, int pay, int rtrd, tipo_pckg tp);
    packet p;
    p = new();
    p.origen  = org[7:0];
    p.destino = dst[7:0];
    p.payload = pay;
    p.retardo = rtrd;
    p.tipo    = tp;
    p.id      = esperados + 1;

    // quien deberia recibirlo, y con que destino/payload
    for (int i = 0; i < drvrs; i++) begin
      if (tp == envio_broadcast) begin
        if (i != org) begin
          esp_rcbd[i]++;
          esp_destino[i].push_back(`BROADCAST);
          esp_payload[i].push_back(pay);
        end
      end
      else if (i == dst && dst != org) begin
        esp_rcbd[i]++;
        esp_destino[i].push_back(dst[7:0]);
        esp_payload[i].push_back(pay);
      end
    end
    return p;
  endfunction

  // busca (destino,payload) en lo esperado de la terminal i y lo saca
  // si lo encuentra; no importa el orden en que haya llegado
  function automatic bit buscar_y_sacar(int i, bit [`ANCHO_DIR-1:0] dst,
                                         bit [ANCHO_PAYLOAD-1:0] pay);
    foreach (esp_destino[i][j]) begin
      if (esp_destino[i][j] == dst && esp_payload[i][j] == pay) begin
        esp_destino[i].delete(j);
        esp_payload[i].delete(j);
        return 1;
      end
    end
    return 0;
  endfunction

  initial begin
    pckg_mon m;
    int      total_esperado;

    for (int i = 0; i < drvrs; i++) esp_rcbd[i] = 0;

    gen_agnt_mbx = new();
    drv_chkr_mbx = new();
    mon_chkr_mbx = new();

    padre_drv = new();
    padre_drv.vif          = _if;
    padre_drv.gen_agnt_mbx = gen_agnt_mbx;
    padre_drv.drv_chkr_mbx = drv_chkr_mbx;

    padre_mon = new();
    padre_mon.vif          = _if;
    padre_mon.mon_chkr_mbx = mon_chkr_mbx;

    fork
      padre_drv.run();
      padre_mon.run();
    join_none

    // los mismos 5 paquetes de prueba_driver.sv, a proposito
    gen_agnt_mbx.put(nuevo(0, 1, 'h11, 0, envio_normal));
    gen_agnt_mbx.put(nuevo(0, 2, 'h22, 0, envio_normal));
    gen_agnt_mbx.put(nuevo(0, 3, 'h33, 0, envio_normal));
    esperados = 3;

    gen_agnt_mbx.put(nuevo(drvrs-1, 0, 'h44, 5, envio_normal));
    esperados = 4;

    gen_agnt_mbx.put(nuevo(1, `BROADCAST, 'h55, 0, envio_broadcast));
    esperados = 5;

    // espera a que salga todo (mismo margen que prueba_driver.sv)
    repeat (10 * (pckg_sz + 2*drvrs + 20)) @(posedge clk);

    total_esperado = 0;
    for (int i = 0; i < drvrs; i++) total_esperado += esp_rcbd[i];

    $display("---- resumen ----");
    $display("paquetes que tomo el DUT (agent_drv)     : %0d", padre_drv.total_enviados());
    $display("recepciones que junto el monitor          : %0d", padre_mon.total_recibidos());
    $display("recepciones esperadas (suma por terminal) : %0d", total_esperado);

    // drena lo que el agent_mon junto y lo compara contra lo esperado
    while (mon_chkr_mbx.num() > 0) begin
      mon_chkr_mbx.get(m);
      m.print("prueba_monitor: visto");

      if (m.t_recibido == 0) begin
        errores++;
        $display("ERROR: pckg_mon de terminal %0d sin t_recibido", m.terminal);
      end

      if (m.terminal < 0 || m.terminal >= drvrs) begin
        errores++;
        $display("ERROR: pckg_mon con terminal invalida (%0d)", m.terminal);
      end
      else if (!buscar_y_sacar(m.terminal, m.destino, m.payload)) begin
        errores++;
        $display("ERROR: terminal %0d recibio destino=0x%0h payload=0x%0h sin esperarlo",
                  m.terminal, m.destino, m.payload);
      end
    end

    // lo que quedo sin sacar es lo que se esperaba y nunca llego
    for (int i = 0; i < drvrs; i++) begin
      if (esp_destino[i].size() != 0) begin
        errores++;
        $display("ERROR: a la terminal %0d le faltaron %0d recepciones",
                  i, esp_destino[i].size());
      end
    end

    if (padre_mon.total_recibidos() != total_esperado) begin
      errores++;
      $display("ERROR: el agent_mon junto %0d y se esperaban %0d",
                padre_mon.total_recibidos(), total_esperado);
    end

    if (errores == 0) $display("==== PRUEBA MONITOR: PASS ====");
    else              $display("==== PRUEBA MONITOR: FAIL (%0d errores) ====", errores);
    $finish;
  end

  initial begin
    #(`PERIODO_CLK * 20000);
    $display("==== PRUEBA MONITOR: TIMEOUT ====");
    $finish;
  end

endmodule
