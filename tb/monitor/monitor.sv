//////////////////////////////////////////////////////////////////////
// monitor: hijo del vigilante, uno por terminal                    //
//////////////////////////////////////////////////////////////////////
// Es el espejo de driver.sv pero mirando hacia afuera del DUT, en vez
// de emular la fifo de entrada, vigila push/D_push (la fifo de
// salida) y arma un pckg_mon con lo que alcanza a ver.
//////////////////////////////////////////////////////////////////////

class monitor;

  virtual bus_if vif;

  int id;  // terminal que vigila

  pckg_mon_mbx mon_agnt_mbx;  // al padre

  int recibidos = 0; // cuántos paquetes vio este hijo en total

  function new(int identificador = 0);
    this.id = identificador;
  endfunction

  task vigilar();
    pckg_mon m;
    forever begin
      @(posedge vif.clk);
      if (vif.push[0][id] === 1'b1) begin // ¿el DUT justo levantó push?
        m = new();
        m.terminal              = id;
        {m.destino, m.payload}  = vif.D_push[0][id];  // parte el dato que llegó en dos: los bits altos van a destino, el resto a payload.
        m.t_recibido            = $time;

        recibidos++;
        mon_agnt_mbx.put(m);
        m.print($sformatf("monitor[%0d]: recibido", id));
      end
    end
  endtask

  task run();
    fork
      vigilar();
    join_none
  endtask

endclass
