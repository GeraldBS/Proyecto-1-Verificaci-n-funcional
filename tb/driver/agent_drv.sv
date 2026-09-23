//////////////////////////////////////////////////////////////////////
// agent_drv: padre del manejador                                   //
//////////////////////////////////////////////////////////////////////
// Crea un hijo por terminal, resetea el DUT y reparte los paquetes
// del generator segun el campo origen.
// El reset va como pulso 0 -> 1 -> 0, el contador del arbitro se
// resetea por flanco y si no nunca sale de X.
//////////////////////////////////////////////////////////////////////

class agent_drv;

  virtual bus_if vif;

  packet_mbx gen_agnt_mbx;  // del generator
  packet_mbx drv_chkr_mbx;  // al checker, compartido por los hijos

  driver     hijos[];
  packet_mbx buzon[];       // un mailbox por hijo

  int profundidad = 8;
  int repartidos  = 0;
  int descartados = 0;

  function new(); // le pasa a cada hijo lo que necesita
    hijos = new[`DRVRS];
    buzon = new[`DRVRS];
    foreach (hijos[i]) begin
      buzon[i] = new();
      hijos[i] = new(i);
    end
  endfunction

  task reset_dut(); // resetea el dut con un ritmo 0-1-0
    for (int i = 0; i < `DRVRS; i++) begin
      vif.pndng[0][i] = 0;   // al inicio estan en X
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

  task run();
    packet p;

    foreach (hijos[i]) begin
      hijos[i].vif          = vif;
      hijos[i].agnt_drv_mbx = buzon[i];
      hijos[i].drv_chkr_mbx = drv_chkr_mbx;
      hijos[i].profundidad  = profundidad;
    end

    reset_dut();
    foreach (hijos[i]) hijos[i].run();

    forever begin
      gen_agnt_mbx.get(p);
      if (p.origen < `DRVRS) begin
        buzon[p.origen].put(p);
        repartidos++;
      end
      else begin
        descartados++;
        $display("[%0t] agent_drv: origen %0d no existe", $time, p.origen);
      end
    end
  endtask

  function int total_enviados(); // Enviados de todos los hijos (contador)
    int t = 0;
    foreach (hijos[i]) t += hijos[i].enviados;
    return t;
  endfunction

endclass
