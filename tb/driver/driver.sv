//////////////////////////////////////////////////////////////////////
// driver: hijo del manejador, uno por cada terminal                //
//////////////////////////////////////////////////////////////////////
// Emula la FIFO de entrada de un dispositivo:
//  - guarda en una cola los paquetes que le manda el padre
//  - mientras haya algo en la cola levanta pndng y pone el dato
//    de adelante en D_pop
//  - cuando el DUT hace pop, marca t_envio y le pasa el paquete
//    al checker
//
// Las senales se mueven en negedge para no chocar con el DUT, que
// muestrea en posedge.
//
// Solo hay un bus, por eso el indice [0] en las senales.
//////////////////////////////////////////////////////////////////////

class driver;

  virtual bus_if vif;

  int id;               // numero de terminal que emula
  int profundidad = 8;  // cuantos paquetes caben en la fifo emulada

  packet_mbx agnt_drv_mbx;  // del padre a este hijo
  packet_mbx drv_chkr_mbx;  // de aqui al checker

  packet cola[$];       // la fifo emulada

  int enviados = 0;     // cuantos paquetes ya tomo el DUT

  function new(int identificador = 0);
    this.id = identificador;
  endfunction

  //////////////////////////////////////////////////////////////////
  // recibe del padre, espera el retardo y encola
  //////////////////////////////////////////////////////////////////
  task recibir();
    packet p;
    forever begin
      agnt_drv_mbx.get(p);

      // espera los ciclos de retardo que trae el paquete
      repeat (p.retardo) @(posedge vif.clk);

      // si la fifo emulada esta llena, espera a que se desocupe
      while (cola.size() >= profundidad) @(posedge vif.clk);

      cola.push_back(p);
    end
  endtask

  //////////////////////////////////////////////////////////////////
  // maneja las senales de la fifo
  //////////////////////////////////////////////////////////////////
  task manejar();
    packet p;
    forever begin
      // en negedge se presenta el dato de adelante de la cola
      @(negedge vif.clk);
      if (cola.size() > 0) begin
        vif.pndng[0][id] = 1;
        vif.D_pop[0][id] = cola[0].palabra();
      end
      else begin
        vif.pndng[0][id] = 0;
      end

      // en posedge se revisa si el DUT lo tomo
      @(posedge vif.clk);
      if (vif.pop[0][id] === 1'b1) begin
        p = cola.pop_front();
        p.t_envio = $time;
        enviados++;
        drv_chkr_mbx.put(p);
      end
    end
  endtask

  //////////////////////////////////////////////////////////////////
  // arranca los dos procesos del hijo
  //////////////////////////////////////////////////////////////////
  task run();
    fork
      recibir();
      manejar();
    join_none
  endtask

endclass
