//////////////////////////////////////////////////////////////////////
// Prueba de humo: prueba dirigida sencilla sin el ambiente todavia //
//////////////////////////////////////////////////////////////////////
// Manda un paquete de cada tipo y revisa quien lo recibe, para ver
// que la interfaz conecta bien con el DUT.
// Las senales se cambian en negedge para no chocar con el DUT.
//////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

// se define FIFOS para que Library.sv no busque ../FIFO_Latches/fifo.sv
`include "fifo.sv"
`define FIFOS
`include "Library.sv"

`include "parametros.svh"
`include "interfaces/interfaz.sv"
`include "pkg/tb_pkg.sv"

module prueba_humo;

  parameter bits    = `BITS;
  parameter drvrs   = `DRVRS;
  parameter pckg_sz = `PCKG_SZ;

  // tiempo de espera: serializar + una vuelta del arbitro + margen
  localparam int CICLOS_ESPERA = pckg_sz + 2*drvrs + 20;

  bit clk = 0;
  always #(`PERIODO_CLK/2.0) clk = ~clk;

  bus_if #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) _if (.clk(clk));

  bs_gnrtr_n_rbtr #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz),
                    .broadcast(`BROADCAST)) dut (
    .clk    (_if.clk),
    .reset  (_if.reset),
    .pndng  (_if.pndng),
    .push   (_if.push),
    .pop    (_if.pop),
    .D_pop  (_if.D_pop),
    .D_push (_if.D_push)
  );

  // monitor sencillo: guarda quien recibe y que recibe
  bit               recibio   [drvrs];
  bit [pckg_sz-1:0] dato_rcbd [drvrs];

  genvar g;
  generate
    for (g = 0; g < drvrs; g++) begin : MON
      always @(posedge clk) begin
        if (_if.push[0][g] === 1'b1) begin
          recibio[g]   = 1;
          dato_rcbd[g] = _if.D_push[0][g];
          $display("[%0t] terminal %0d recibe 0x%0h", $time, g, _if.D_push[0][g]);
        end
      end
    end
  endgenerate

  int errores = 0;

  // manda un paquete desde p.origen y revisa quien lo recibe
  task automatic enviar_y_revisar(packet p);
    bit esperado [drvrs];
    time t_pop;

    // quien deberia recibirlo
    for (int i = 0; i < drvrs; i++) begin
      case (p.tipo)
        envio_normal    : esperado[i] = (i == p.destino);
        envio_broadcast : esperado[i] = (i != p.origen);
        default         : esperado[i] = 0; // error o propio: nadie
      endcase
      recibio[i] = 0;
    end

    p.print("Humo: enviando");

    // ponemos el dato en la fifo del origen
    @(negedge clk);
    _if.D_pop[0][p.origen] = p.palabra();
    _if.pndng[0][p.origen] = 1;

    // esperamos el pop y bajamos pndng
    do @(posedge clk); while (_if.pop[0][p.origen] !== 1'b1);
    t_pop = $time;
    @(negedge clk);
    _if.pndng[0][p.origen] = 0;

    // esperamos a que llegue
    repeat (CICLOS_ESPERA) @(posedge clk);

    for (int i = 0; i < drvrs; i++) begin
      if (recibio[i] != esperado[i]) begin
        errores++;
        $display("ERROR: terminal %0d recibio=%0b esperado=%0b", i, recibio[i], esperado[i]);
      end else if (recibio[i] && dato_rcbd[i] != p.palabra()) begin
        errores++;
        $display("ERROR: terminal %0d dato=0x%0h esperado=0x%0h", i, dato_rcbd[i], p.palabra());
      end
    end
  endtask

  // secuencia de la prueba
  initial begin
    packet p;

    // fifos vacias al inicio
    for (int i = 0; i < drvrs; i++) begin
      _if.pndng[0][i] = 0;
      _if.D_pop[0][i] = 0;
    end

    // reset como pulso, si no el arbitro queda en X
    _if.reset = 0;
    repeat (2) @(negedge clk);
    _if.reset = 1;
    repeat (3) @(negedge clk);
    _if.reset = 0;
    repeat (5) @(negedge clk);

    $display("==== Prueba de humo: PCKG_SZ=%0d DRVRS=%0d ====", pckg_sz, drvrs);

    // unicast 0 -> 1
    p = new();
    p.tipo = envio_normal;    p.origen = 0; p.destino = 1;
    p.payload = '1;           p.id = 1;
    enviar_y_revisar(p);

    // broadcast desde el ultimo
    p = new();
    p.tipo = envio_broadcast; p.origen = drvrs-1; p.destino = `BROADCAST;
    p.payload = {(pckg_sz/2){2'b10}}; p.id = 2;   // 1010...
    enviar_y_revisar(p);

    // destino que no existe
    p = new();
    p.tipo = envio_error;     p.origen = 0; p.destino = drvrs;
    p.payload = 'h5A;         p.id = 3;
    enviar_y_revisar(p);

    // destino igual al origen
    p = new();
    p.tipo = envio_propio;    p.origen = 1; p.destino = 1;
    p.payload = 'hC3;         p.id = 4;
    enviar_y_revisar(p);

    if (errores == 0) $display("==== PRUEBA DE HUMO: PASS ====");
    else              $display("==== PRUEBA DE HUMO: FAIL (%0d errores) ====", errores);
    $finish;
  end

  // por si el DUT nunca hace pop
  initial begin
    #(`PERIODO_CLK * (4 * CICLOS_ESPERA + 200));
    $display("==== PRUEBA DE HUMO: TIMEOUT ====");
    $finish;
  end

endmodule
