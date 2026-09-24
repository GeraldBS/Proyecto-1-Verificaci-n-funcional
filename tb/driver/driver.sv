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

  packet_mbx agnt_drv_mbx;  // del padre
  packet_mbx drv_chkr_mbx;  // al checker

  packet cola[$];       // la fifo emulada, es infinita: no tiene tope
  int enviados      = 0;
  int pops_vacios   = 0;   // el DUT hizo pop sin que hubiera nada
  int coincidencias = 0;   // entro un dato justo cuando salia otro

  time t_ultimo_push = -1; // cuando se encolo el ultimo
  time t_ultimo_pop  = -1; // cuando salio el ultimo

  function new(int identificador = 0);
    this.id = identificador;
  endfunction

  // saca del mailbox, espera el retardo y encola
  task recibir();
    packet p;
    forever begin
      agnt_drv_mbx.get(p);
      repeat (p.retardo) @(posedge vif.clk);
      cola.push_back(p);
      t_ultimo_push = $time;   // para ver si coincide con un pop
    end
  endtask

  // mueve las senales de la fifo
  task manejar();
    packet p;
    forever begin 
      @(negedge vif.clk); // muestra el paquete

      // La coincidencia se revisa aqui, en negedge, y no en el mismo
      // posedge: recibir() y manejar() corren en el mismo flanco y el
      // orden entre ellos no esta definido, asi que en posedge la
      // coincidencia se ve o no segun cual corrio primero.
      if (t_ultimo_pop >= 0 && t_ultimo_pop == t_ultimo_push) begin
        coincidencias++;
        t_ultimo_pop = -1;
      end

      if (cola.size() > 0) begin
        vif.pndng[0][id] = 1;             // solo hay un bus, de ahi el [0]
        vif.D_pop[0][id] = cola[0].palabra();
      end
      else begin
        vif.pndng[0][id] = 0;
      end

      @(posedge vif.clk); // mira si el DUT lo tomo
      if (vif.pop[0][id] === 1'b1 && cola.size() == 0) begin
        // esquina: pop con la cola vacía. No deberia pasar nunca,
        // porque en ese caso pndng esta en 0. Si pasa, es bug del DUT.
        pops_vacios++;
        $display("[%0t] driver[%0d]: ERROR pop con la cola vacía", $time, id);
      end
      else if (vif.pop[0][id] === 1'b1) begin  // el DUT ya lo tomo
        t_ultimo_pop = $time;
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
