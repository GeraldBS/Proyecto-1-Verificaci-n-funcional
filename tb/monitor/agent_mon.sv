//////////////////////////////////////////////////////////////////////
// agent_mon: padre del vigilante                                   //
//////////////////////////////////////////////////////////////////////
// Espejo de agent_drv: crea un hijo (monitor) por terminal y junta
// lo que cada uno ve en un solo mailbox hacia el checker.
//
// A diferencia de agent_drv (que reparte paquetes del generator
// hacia el hijo correcto segun el campo origen), aqui no hay nada
// que repartir: cada hijo ya sabe exactamente que termino vigilando,
// asi que el padre solo junta (drena el buzon de cada hijo) y
// reenvia para adelante. Un proceso "recolectar" por hijo, todos
// escribiendo al mismo mon_chkr_mbx.
//////////////////////////////////////////////////////////////////////

class agent_mon;

  virtual bus_if vif;

  pckg_mon_mbx mon_chkr_mbx;  // al checker

  monitor      hijos[];
  pckg_mon_mbx buzon[];       // un mailbox por hijo, lo llena el propio hijo

  int recibidos = 0;

  function new();
    hijos = new[`DRVRS];
    buzon = new[`DRVRS];
    foreach (hijos[i]) begin
      buzon[i] = new();
      hijos[i] = new(i);
    end
  endfunction

  // drena el buzon del hijo i y lo manda al checker
  task recolectar(int i);
    pckg_mon m;
    forever begin
      buzon[i].get(m);
      recibidos++;
      mon_chkr_mbx.put(m);
    end
  endtask

  task run();
    foreach (hijos[i]) begin
      hijos[i].vif           = vif;
      hijos[i].mon_agnt_mbx  = buzon[i];
    end

    foreach (hijos[i]) hijos[i].run();

    foreach (buzon[i]) begin
      automatic int idx = i;  // sin esto todos los fork verian el mismo i
      fork
        recolectar(idx);
      join_none
    end
  endtask

  function int total_recibidos();
    int t = 0;
    foreach (hijos[i]) t += hijos[i].recibidos;
    return t;
  endfunction

endclass
