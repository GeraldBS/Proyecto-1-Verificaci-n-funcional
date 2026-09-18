//////////////////////////////////////////////////////////////////////
// generator: crea los paquetes aleatorios                          //
//////////////////////////////////////////////////////////////////////
// Recibe la cfg del test y con eso genera num paquetes.
// Todo lo que controla la aleatorizacion sale de la cfg, aqui no
// hay nada fijo.
//////////////////////////////////////////////////////////////////////

class generator;

  cfg_mbx    tst_gen_mbx;   // config, viene del test
  packet_mbx gen_agnt_mbx;  // los paquetes, van al agente

  int num;        // cuantos paquetes generar
  int max_delay;
  int generados = 0;

  task run();
    cfg    config_item;
    packet item;

    tst_gen_mbx.get(config_item);   // primero espera la config
    num       = config_item.num;
    max_delay = config_item.max_delay;
    $display("[%0t] generator: va a generar %0d paquetes", $time, num);

    for (int i = 0; i < num; i++) begin
      item = new();

      // los controles de la aleatorizacion salen de la cfg
      item.min_retardo    = config_item.min_delay;
      item.max_retardo    = config_item.max_delay;
      item.peso_normal    = config_item.peso_normal;
      item.peso_broadcast = config_item.peso_broadcast;
      item.peso_error     = config_item.peso_error;
      item.peso_propio    = config_item.peso_propio;

      if (!item.randomize()) begin   // si no avisa, el paquete sale con basura
        $display("[%0t] generator: fallo randomize en el paquete %0d", $time, i+1);
        $finish;
      end

      item.id = i + 1;
      generados++;
      gen_agnt_mbx.put(item);
    end

    $display("[%0t] generator: genero %0d paquetes", $time, generados);
  endtask

endclass
