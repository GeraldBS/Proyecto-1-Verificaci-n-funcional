//////////////////////////////////////////////////////////////////////
// generator: crea los paquetes aleatorios                          //
//////////////////////////////////////////////////////////////////////
// Recibe la cfg del test, que ya trae cuántas transacciones le toca a
// cada terminal, y las va sacando por turnos entre ellas.
// Por turnos y no terminal por terminal, para que haya varias mandando
// a la vez y el árbitro tenga que decidir.
//////////////////////////////////////////////////////////////////////

class generator;

  cfg_mbx    tst_gen_mbx;   // config, viene del test
  packet_mbx gen_agnt_mbx;  // los paquetes, van al agente

  int generados = 0;
  bit terminado = 0;        // el test lo espera para saber cuándo parar

  task run();
    cfg    config_item;
    packet item;
    int    faltan[];
    int    quedan;

    tst_gen_mbx.get(config_item);   // primero espera la config

    faltan = new[`DRVRS];
    foreach (faltan[i]) faltan[i] = config_item.trans_x_terminal[i];
    quedan = config_item.total();

    $display("[%0t] generator: va a generar %0d paquetes", $time, quedan);

    while (quedan > 0) begin
      foreach (faltan[i]) begin   // una vuelta por todas las terminales
        if (faltan[i] > 0) begin  // ¿a esta todavía le quedan?
          item = new();

          // los controles de la aleatorización salen de la cfg
          item.min_retardo    = config_item.min_delay;
          item.max_retardo    = config_item.max_delay;
          item.peso_normal    = config_item.peso_normal;
          item.peso_broadcast = config_item.peso_broadcast;
          item.peso_error     = config_item.peso_error;
          item.peso_propio    = config_item.peso_propio;

          // el origen lo fija el turno, el resto se aleatoriza
          if (!item.randomize() with {origen == i;}) begin
            $display("[%0t] generator: fallo randomize en el paquete %0d",
                     $time, generados+1);
            $finish;
          end

          item.id = generados + 1;
          generados++;
          gen_agnt_mbx.put(item);

          faltan[i]--;
          quedan--;
        end
      end
    end

    terminado = 1;
    $display("[%0t] generator: genero %0d paquetes", $time, generados);
  endtask

endclass
