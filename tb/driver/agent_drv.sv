//////////////////////////////////////////////////////////////////////
// agent_drv: padre del manejador                                   //
//////////////////////////////////////////////////////////////////////
// - crea un hijo (driver) por cada terminal
// - hace el reset del DUT
// - recibe los paquetes del generator y los reparte al hijo que
//   corresponde segun el campo origen
//
// El reset tiene que ser un pulso 0 -> 1 -> 0: el contador del
// arbitro del DUT se resetea por flanco, si reset se queda en 1
// desde el inicio el arbitro nunca sale de X.
//////////////////////////////////////////////////////////////////////

class agent_drv;

  virtual bus_if vif;

  packet_mbx gen_agnt_mbx;  // del generator a este padre
  packet_mbx drv_chkr_mbx;  // al checker, lo comparten todos los hijos

  driver     hijos[];       // un hijo por terminal
  packet_mbx buzon[];       // un mailbox por hijo

  int profundidad = 8;      // tamano de cada fifo emulada
  int repartidos  = 0;      // cuantos paquetes ha repartido
  int descartados = 0;      // paquetes con origen invalido

  function new();
    hijos = new[`DRVRS];
    buzon = new[`DRVRS];
    foreach (hijos[i]) begin
      buzon[i] = new();
      hijos[i] = new(i);
    end
  endfunction

  //////////////////////////////////////////////////////////////////
  // deja las senales en un estado conocido y aplica el reset
  //////////////////////////////////////////////////////////////////
  task reset_dut();
    for (int i = 0; i < `DRVRS; i++) begin
      vif.pndng[0][i] = 0;
      vif.D_pop[0][i] = 0;
    end

    vif.reset = 0;
    repeat (2) @(negedge vif.clk);
    vif.reset = 1;
    repeat (3) @(negedge vif.clk);
    vif.reset = 0;
    repeat (2) @(negedge vif.clk);

    $display("[%0t] agent_drv: reset aplicado", $time);
  endtask

  //////////////////////////////////////////////////////////////////
  // conecta los hijos, resetea y reparte
  //////////////////////////////////////////////////////////////////
  task run();
    packet p;

    foreach (hijos[i]) begin
      hijos[i].vif          = vif;
      hijos[i].agnt_drv_mbx = buzon[i];
      hijos[i].drv_chkr_mbx = drv_chkr_mbx;
      hijos[i].profundidad  = profundidad;
    end

    reset_dut();

    // cada hijo arranca sus propios procesos
    foreach (hijos[i]) hijos[i].run();

    forever begin
      gen_agnt_mbx.get(p);
      if (p.origen < `DRVRS) begin
        buzon[p.origen].put(p);
        repartidos++;
      end
      else begin
        descartados++;
        $display("[%0t] agent_drv: origen %0d no existe, se descarta", $time, p.origen);
      end
    end
  endtask

  //////////////////////////////////////////////////////////////////
  // cuantos paquetes ya tomo el DUT en total
  //////////////////////////////////////////////////////////////////
  function int total_enviados();
    int t = 0;
    foreach (hijos[i]) t += hijos[i].enviados;
    return t;
  endfunction

endclass
