//////////////////////////////////////////////////////////////////////
// test_corner: casos de esquina del test plan                      //
//////////////////////////////////////////////////////////////////////
// Son pruebas dirigidas: los paquetes se arman a mano y se meten
// directo al agente, sin pasar por el generator. El scoreboard y el
// checker siguen trabajando igual, asi que cada caso se verifica
// solo.
//
// Casos que cubre esta tanda:
//   1. todos los dispositivos pidiendo el bus en el mismo ciclo
//   2. rafagas de mensajes con error desde el mismo terminal
//   3. retardo justo en el minimo y en el maximo
//   4. patron alternante (checkerboard) en el payload
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

  task run();
    void'($value$plusargs("max_delay=%d", max_delay));

    arrancar();
    $display("[%0t] test_corner: PCKG_SZ=%0d DRVRS=%0d", $time, `PCKG_SZ, `DRVRS);

    caso_simultaneos();
    caso_rafaga_errores();
    caso_retardos_borde();
    caso_checkerboard();

    $display("\n---- resumen de los casos de esquina ----");
    $display("paquetes inyectados : %0d", sig_id);
    reporte_final();
  endtask

endclass
