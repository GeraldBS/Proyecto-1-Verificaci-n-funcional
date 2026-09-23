//////////////////////////////////////////////////////////////////////
// test: arma la cfg, arranca el ambiente y espera a que termine    //
//////////////////////////////////////////////////////////////////////
// Los valores se pueden cambiar sin recompilar con plusargs:
//   ./salida +min_trans=5 +max_trans=80 +max_delay=12 +p_bdcst=20
//////////////////////////////////////////////////////////////////////

class test;

  virtual bus_if vif;

  env e0;
  cfg_mbx       tst_gen_mbx;   // mailbox con el generator
  escenario_mbx tst_agnt_mbx;  // mailbox con el agente

  function new();
    e0           = new();
    tst_gen_mbx  = new();
    tst_agnt_mbx = new();

    e0.tst_gen_mbx  = tst_gen_mbx;
    e0.tst_agnt_mbx = tst_agnt_mbx;
  endfunction

  task run();
    cfg       config_item;
    escenario esc_item;
    int       espera;
    int       tope;

    e0.vif = vif;
    e0.run();              // join_none adentro, arranca el ambiente

    config_item = new();

    // valores por defecto, se pueden cambiar con plusargs
    config_item.min_trans      = 1;
    config_item.max_trans      = 10;
    config_item.min_delay      = 0;
    config_item.max_delay      = 8;
    config_item.peso_normal    = 80;
    config_item.peso_broadcast = 10;
    config_item.peso_error     = 10;
    config_item.peso_propio    = 0;

    void'($value$plusargs("min_trans=%d", config_item.min_trans));
    void'($value$plusargs("max_trans=%d", config_item.max_trans));
    void'($value$plusargs("min_delay=%d", config_item.min_delay));
    void'($value$plusargs("max_delay=%d", config_item.max_delay));
    void'($value$plusargs("p_nrml=%d",    config_item.peso_normal));
    void'($value$plusargs("p_bdcst=%d",   config_item.peso_broadcast));
    void'($value$plusargs("p_err=%d",     config_item.peso_error));
    void'($value$plusargs("p_prp=%d",     config_item.peso_propio));
    void'($value$plusargs("prof=%d",      e0.profundidad));

    // aquí se sortea cuántas transacciones manda cada terminal
    if (!config_item.randomize()) begin
      $display("[%0t] test: fallo randomize de la cfg", $time);
      $finish;
    end

    config_item.print("test: config");

    tst_gen_mbx.put(config_item);

    esc_item = new();
    tst_agnt_mbx.put(esc_item);

    // espera a que el generator termine de sacarlos todos
    while (!e0.gen0.terminado) @(posedge vif.clk);

    // y a que el DUT los haya tomado
    while (e0.agnt_drv0.total_enviados() < e0.gen0.generados)
      @(posedge vif.clk);

    // Espera a que no quede nada pendiente en el scoreboard, en vez de
    // un tiempo fijo. El margen fijo se queda corto: el retraso de un
    // paquete depende de cuantos haya adelante en el arbitro, y con
    // mucho trafico puede ser mucho mayor que el de un paquete solo.
    // El tope corta si de verdad se perdio algo, para no colgar la sim.
    // primero que el scoreboard termine de anotar lo que ya salio
    while (e0.drv_chkr_mbx.num() > 0) @(posedge vif.clk);

    espera = 0;
    tope   = (`PCKG_SZ + 4*`DRVRS + 20) * (e0.gen0.generados + 10);
    while (e0.sb0.esperando_q.size() > 0 && espera < tope) begin
      @(posedge vif.clk);
      espera++;
    end
    if (espera >= tope)
      $display("[%0t] test: se acabo la espera con %0d entregas pendientes",
               $time, e0.sb0.esperando_q.size());

    // unos ciclos mas por si algo venia en camino
    repeat (20) @(posedge vif.clk);

    $display("---- resumen ----");
    $display("generados por el generator : %0d", e0.gen0.generados);
    $display("repartidos por el padre    : %0d", e0.agnt_drv0.repartidos);
    $display("tomados por el DUT (pop)   : %0d", e0.agnt_drv0.total_enviados());
    $display("vistos por el monitor      : %0d", e0.agnt_mon0.total_recibidos());

    // deja que el checker termine de vaciar su mailbox
    while (e0.mon_chkr_mbx.num() > 0) @(posedge vif.clk);
    repeat (10) @(posedge vif.clk);

    e0.chkr0.reporte();
    e0.sb0.reporte();
    e0.sb0.escribir_csv();

    if (e0.chkr0.errores() == 0) $display("==== PRUEBA: PASS ====");
    else $display("==== PRUEBA: FAIL (%0d errores) ====", e0.chkr0.errores());
  endtask

endclass
