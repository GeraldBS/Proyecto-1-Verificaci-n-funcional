//////////////////////////////////////////////////////////////////////
// test_corner: casos de esquina del test plan                      //
//////////////////////////////////////////////////////////////////////
// Son pruebas dirigidas: los paquetes se arman a mano y se meten
// directo al agente, sin pasar por el generator. El scoreboard y el
// checker siguen trabajando igual, asi que cada caso se verifica
// solo.
//
// Casos que cubre:
//   1. todos los dispositivos pidiendo el bus en el mismo ciclo
//   2. rafagas de mensajes con error desde el mismo terminal
//   3. retardo justo en el minimo y en el maximo
//   4. patron alternante (checkerboard) en el payload
//   5. direcciones justo en los bordes del rango
//   6. todos los terminales mandando al mismo destino
//   7. actividad alternante entre pares de terminales
//   8. varios dispositivos operando a la vez, mezclando tipos
//   9. datos entrando a una fifo mientras el DUT saca de ella
//
// Hay un caso del plan que no se inyecta sino que se vigila dentro
// del driver, porque no es estimulo sino propiedad:
//   - pop con la fifo vacía (el DUT no deberia hacerlo nunca)
//////////////////////////////////////////////////////////////////////

class test_corner extends base_test;

  localparam int PAYLOAD = `PCKG_SZ - `ANCHO_DIR;

  int max_delay = 10;   // se usa en el caso 3

  //////////////////////////////////////////////////////////////////
  // 1. varios terminales piden el bus a la vez
  // se repite con 2, 3 ... hasta DRVRS solicitantes
  //////////////////////////////////////////////////////////////////
  task caso_simultaneos();
    packet p;
    for (int n = 2; n <= `DRVRS; n++) begin
      $display("\n[%0t] === esquina 1: %0d terminales piden el bus a la vez ===",
               $time, n);
      for (int d = 0; d < n; d++) begin
        // retardo 0 para que entren todos en el mismo ciclo
        p = armar(d, (d+1) % `DRVRS, 'hA0 + d, 0, envio_normal);
        inyectar(p);
      end
      esperar_fin();
    end
  endtask

  //////////////////////////////////////////////////////////////////
  // 2. mensajes con error seguidos desde el mismo terminal
  // se varia el largo de la rafaga: 3, 5 y 10
  //////////////////////////////////////////////////////////////////
  task caso_rafaga_errores();
    packet p;
    int largos[3] = '{3, 5, 10};

    foreach (largos[k]) begin
      $display("\n[%0t] === esquina 2: rafaga de %0d errores seguidos ===",
               $time, largos[k]);
      for (int i = 0; i < largos[k]; i++) begin
        // destinos que no existen, pero distintos del broadcast
        p = armar(0, `DRVRS + i, 'h5A, 0, envio_error);
        inyectar(p);
      end
      // uno bueno al final, para ver que el bus sigue sirviendo
      p = armar(0, 1, 'h77, 0, envio_normal);
      inyectar(p);
      esperar_fin();
    end
  endtask

  //////////////////////////////////////////////////////////////////
  // 3. retardo en los bordes del rango, no adentro
  //////////////////////////////////////////////////////////////////
  task caso_retardos_borde();
    packet p;
    int bordes[2];
    bordes = '{0, max_delay};

    foreach (bordes[k]) begin
      $display("\n[%0t] === esquina 3: retardo fijo en %0d ciclos ===",
               $time, bordes[k]);
      for (int d = 0; d < `DRVRS; d++) begin
        p = armar(d, (d+1) % `DRVRS, 'hC0 + d, bordes[k], envio_normal);
        inyectar(p);
      end
      esperar_fin();
    end
  endtask

  //////////////////////////////////////////////////////////////////
  // 4. patron alternante en el payload
  // se mandan varios seguidos con el mismo patron, alternando 1010
  // y 0101, que es donde se ve el acople entre bits vecinos
  //////////////////////////////////////////////////////////////////
  task caso_checkerboard();
    packet p;
    bit [PAYLOAD-1:0] patron;
    int seguidos = 5;

    for (int v = 0; v < 2; v++) begin
      patron = (v == 0) ? {(PAYLOAD/2){2'b10}} : {(PAYLOAD/2){2'b01}};
      $display("\n[%0t] === esquina 4: payload 0x%0h, %0d seguidos ===",
               $time, patron, seguidos);
      for (int i = 0; i < seguidos; i++) begin
        p = armar(0, 1, patron, 0, envio_normal);
        inyectar(p);
      end
      esperar_fin();
    end
  endtask


  //////////////////////////////////////////////////////////////////
  // 5. direcciones en los bordes del rango
  // el DUT decide con una comparacion de 8 bits, y los bordes son
  // donde se ven los errores de < contra <=
  //////////////////////////////////////////////////////////////////
  task caso_bordes_direccion();
    packet p;
    int dst;
    int bordes[5];
    bordes = '{0, `DRVRS-1, `DRVRS, 8'hFE, 8'hFF};

    $display("\n[%0t] === esquina 5: direcciones en los bordes ===", $time);
    foreach (bordes[k]) begin
      dst = bordes[k];
      // se manda desde el terminal 1 para que destino 0 no sea auto-envio
      if (dst == 8'hFF)          p = armar(1, dst, 'hB0+k, 0, envio_broadcast);
      else if (dst >= `DRVRS)    p = armar(1, dst, 'hB0+k, 0, envio_error);
      else if (dst == 1)         p = armar(0, dst, 'hB0+k, 0, envio_normal);
      else                       p = armar(1, dst, 'hB0+k, 0, envio_normal);
      $display("[%0t]     destino 0x%0h", $time, dst);
      inyectar(p);
      esperar_fin();
    end
  endtask

  //////////////////////////////////////////////////////////////////
  // 6. todos mandando al mismo destino (el caso contrario al
  // broadcast: en vez de uno a todos, todos a uno)
  //////////////////////////////////////////////////////////////////
  task caso_todos_a_uno();
    packet p;
    int rondas = 3;

    for (int dst = 0; dst < `DRVRS; dst++) begin
      $display("\n[%0t] === esquina 6: todos mandando al terminal %0d ===",
               $time, dst);
      for (int r = 0; r < rondas; r++)
        for (int org = 0; org < `DRVRS; org++)
          if (org != dst) begin   // el auto-envio lo descarta el DUT
            p = armar(org, dst, 'hD0 + org, 0, envio_normal);
            inyectar(p);
          end
      esperar_fin();
    end
  endtask

  //////////////////////////////////////////////////////////////////
  // 7. actividad alternante: un par manda, despues el otro par
  // se varia cada cuantas rondas se alterna
  //////////////////////////////////////////////////////////////////
  task caso_alternante();
    packet p;
    int periodos[2] = '{1, 3};
    int par_a[2];
    int par_b[2];

    if (`DRVRS < 4) begin
      $display("\n[%0t] === esquina 7: se salta, hacen falta 4 terminales ===",
               $time);
      return;
    end

    par_a = '{0, 1};
    par_b = '{2, 3};

    foreach (periodos[k]) begin
      $display("\n[%0t] === esquina 7: alternancia cada %0d rondas ===",
               $time, periodos[k]);
      for (int vuelta = 0; vuelta < 4; vuelta++) begin
        for (int r = 0; r < periodos[k]; r++) begin
          if (vuelta % 2 == 0) begin
            p = armar(par_a[0], par_a[1], 'hE0, 0, envio_normal); inyectar(p);
            p = armar(par_a[1], par_a[0], 'hE1, 0, envio_normal); inyectar(p);
          end
          else begin
            p = armar(par_b[0], par_b[1], 'hE2, 0, envio_normal); inyectar(p);
            p = armar(par_b[1], par_b[0], 'hE3, 0, envio_normal); inyectar(p);
          end
        end
        esperar_fin();
      end
    end
  endtask

  //////////////////////////////////////////////////////////////////
  // 8. varios dispositivos a la vez mezclando tipos de envio
  //////////////////////////////////////////////////////////////////
  task caso_mixto();
    packet p;
    $display("\n[%0t] === esquina 8: varios a la vez, tipos mezclados ===",
             $time);
    for (int d = 0; d < `DRVRS; d++) begin
      case (d % 3)
        0: p = armar(d, (d+1) % `DRVRS, 'hF0+d, 0, envio_normal);
        1: p = armar(d, `BROADCAST,     'hF0+d, 0, envio_broadcast);
        2: p = armar(d, `DRVRS + d,     'hF0+d, 0, envio_error);
      endcase
      inyectar(p);
    end
    esperar_fin();
  endtask


  //////////////////////////////////////////////////////////////////
  // 9. datos entrando a una fifo mientras el DUT saca de ella
  // primero se llena un poco y despues se alimenta de a poquitos,
  // para que en algun ciclo coincidan el que entra y el que sale
  //////////////////////////////////////////////////////////////////
  task caso_push_con_pop();
    packet p;
    int arranque = 5;
    int goteo    = 40;

    $display("\n[%0t] === esquina 9: entran datos mientras salen otros ===",
             $time);

    // arranque: unos cuantos de una vez para que haya cola
    for (int i = 0; i < arranque; i++) begin
      p = armar(0, 1, 'h30 + i, 0, envio_normal);
      inyectar(p);
    end

    // goteo: uno por ciclo, mientras el DUT va sacando
    for (int i = 0; i < goteo; i++) begin
      p = armar(0, 1, 'h40 + i, 1, envio_normal);
      inyectar(p);
    end

    esperar_fin();
    $display("[%0t]     coincidencias hasta aqui: %0d", $time,
             e0.agnt_drv0.total_coincidencias());
  endtask

  task run();
    void'($value$plusargs("max_delay=%d", max_delay));

    arrancar();
    $display("[%0t] test_corner: PCKG_SZ=%0d DRVRS=%0d", $time, `PCKG_SZ, `DRVRS);

    caso_simultaneos();
    caso_rafaga_errores();
    caso_retardos_borde();
    caso_checkerboard();
    caso_bordes_direccion();
    caso_todos_a_uno();
    caso_alternante();
    caso_mixto();
    caso_push_con_pop();

    $display("\n---- resumen de los casos de esquina ----");
    $display("paquetes inyectados     : %0d", sig_id);
    $display("pop con la cola vacía   : %0d (debe ser 0)",
             e0.agnt_drv0.total_pops_vacios());
    $display("push y pop en el mismo ciclo : %0d",
             e0.agnt_drv0.total_coincidencias());
    reporte_final();
  endtask

endclass
