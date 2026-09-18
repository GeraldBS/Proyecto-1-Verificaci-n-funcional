//////////////////////////////////////////////////////////////////////
// driver: hijo del manejador, uno por terminal                     //
//////////////////////////////////////////////////////////////////////
// Emula la fifo de entrada de un dispositivo. Guarda los paquetes
// en una cola, levanta pndng y pone el de adelante en D_pop.
// Cuando el DUT hace pop marca t_envio y lo manda al checker.
// Las senales se mueven en negedge porque el DUT lee en posedge.
//////////////////////////////////////////////////////////////////////

class driver;

  virtual bus_if vif;

  int id;               // terminal que emula
  int profundidad = 8;  // cuantos paquetes caben en la cola

  packet_mbx agnt_drv_mbx;  // del padre
  packet_mbx drv_chkr_mbx;  // al checker

  packet cola[$];       // la fifo emulada
  int enviados = 0;

  function new(int identificador = 0);
    this.id = identificador;
  endfunction

  // saca del mailbox, espera el retardo y encola
  task recibir();
    packet p;
    forever begin
      agnt_drv_mbx.get(p);
      repeat (p.retardo) @(posedge vif.clk);
      while (cola.size() >= profundidad) @(posedge vif.clk); // cola llena
      cola.push_back(p);
    end
  endtask

  // mueve las senales de la fifo
  task manejar();
    packet p;
    forever begin
      @(negedge vif.clk);
      if (cola.size() > 0) begin
        vif.pndng[0][id] = 1;             // solo hay un bus, de ahi el [0]
        vif.D_pop[0][id] = cola[0].palabra();
      end
      else begin
        vif.pndng[0][id] = 0;
      end

      @(posedge vif.clk);
      if (vif.pop[0][id] === 1'b1) begin  // el DUT ya lo tomo
        p = cola.pop_front();
        p.t_envio = $time;
        enviados++;
        drv_chkr_mbx.put(p);
      end
    end
  endtask

  task run();
    fork
      recibir();
      manejar();
    join_none
  endtask

endclass
