//////////////////////////////////////////////////////////////////////
// base_test: lo que comparten todas las pruebas                    //
//////////////////////////////////////////////////////////////////////
// Arma el ambiente, lo arranca y sabe esperar a que todo termine y
// sacar el reporte. Las pruebas de verdad heredan de aqui y solo
// escriben run(), que es lo unico que cambia entre una y otra.
//////////////////////////////////////////////////////////////////////

class base_test;

  virtual bus_if vif;

  env           e0;
  cfg_mbx       tst_gen_mbx;
  escenario_mbx tst_agnt_mbx;

  int sig_id = 0;   // contador de ids para los paquetes dirigidos

  function new();
    e0           = new();
    tst_gen_mbx  = new();
    tst_agnt_mbx = new();

    e0.tst_gen_mbx  = tst_gen_mbx;
    e0.tst_agnt_mbx = tst_agnt_mbx;
  endfunction

  // la escribe cada prueba
  virtual task run();
  endtask

  task arrancar();
    e0.vif = vif;
    e0.run();               // join_none adentro
  endtask

  // paquete armado a mano, para las pruebas dirigidas
  function packet armar(int org, int dst, int pay, int rtrd, tipo_pckg tp);
    packet p = new();
    sig_id++;
    p.origen  = org[7:0];
    p.destino = dst[7:0];
    p.payload = pay;
    p.retardo = rtrd;
    p.tipo    = tp;
    p.id      = sig_id;
    return p;
  endfunction

  // lo mete directo al agente, sin pasar por el generator
  task inyectar(packet p);
    e0.gen_agnt_mbx.put(p);
  endtask

  // espera a que no quede nada pendiente en ningun lado
  task esperar_fin(int tope_ciclos = 100000);
    int espera = 0;

    while (e0.gen_agnt_mbx.num() > 0) @(posedge vif.clk);
    while (e0.drv_chkr_mbx.num() > 0) @(posedge vif.clk);

    while (e0.sb0.esperando_q.size() > 0 && espera < tope_ciclos) begin
      @(posedge vif.clk);
      espera++;
    end
    if (espera >= tope_ciclos)
      $display("[%0t] base_test: se acabo la espera con %0d pendientes",
               $time, e0.sb0.esperando_q.size());

    repeat (20) @(posedge vif.clk);
    while (e0.mon_chkr_mbx.num() > 0) @(posedge vif.clk);
    repeat (10) @(posedge vif.clk);
  endtask

  function void reporte_final();
    e0.chkr0.reporte();
    e0.sb0.reporte();
    e0.sb0.escribir_csv();

    if (e0.chkr0.errores() == 0) $display("==== PRUEBA: PASS ====");
    else $display("==== PRUEBA: FAIL (%0d errores) ====", e0.chkr0.errores());
  endfunction

endclass
