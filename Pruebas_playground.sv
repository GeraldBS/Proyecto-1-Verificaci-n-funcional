
//////////////// Prueba no es generacion propia //////////////////////

class packet;
  rand bit [15:0] payload;
  rand int        retardo;
  int             max_retardo = 10;

  constraint c_retardo { retardo inside {[0:max_retardo]}; }

  function void print(string tag = "");
    $display("[%0t] %s payload=0x%0h retardo=%0d", $time, tag, payload, retardo);
  endfunction
endclass


class cfg;
  int num;
  int max_delay;
endclass

class escenario;
  // aun sin definir: tipo de secuencia, parametros del escenario, etc.
  // por ahora solo necesitamos que exista para que el test compile.
endclass

typedef mailbox #(packet)    packet_mbx;
typedef mailbox #(cfg)       cfg_mbx;
typedef mailbox #(escenario) escenario_mbx;

//////////////////////////////////////////////////////////////////
// generator mismo codigo
//////////////////////////////////////////////////////////////////

class generator;
  cfg_mbx      tst_gen_mbx;    // config, viene del Test
  packet_mbx   gen_agnt_mbx;   // transaction, va hacia el Agent
  event        agnt_done;      // el Agent avisa cuando ya proceso el item

  int num;       // parametrizable
  int max_delay; // parametrizable

  task run ();
    cfg config_item;
    tst_gen_mbx.get(config_item);     // primero recibe la config
    num = config_item.num;
    max_delay = config_item.max_delay;
    for (int i = 0; i < num; i++) begin
      packet item = new;
      item.max_retardo = max_delay;
      item.randomize();
      $display("Generator: [%0t] Generated item %0d/%0d", $time, i+1, num);
      gen_agnt_mbx.put(item);
      @(agnt_done);
    end
    $display("Generator: [%0t] Finished generating %0d items", $time, num);
  endtask
endclass

//////////////// Prueba no es generacion propia //////////////////////

class env;
  generator gen0;

  cfg_mbx       tst_gen_mbx;    // Test -> env, lo reenviamos al Generator
  escenario_mbx tst_agnt_mbx;   // Test -> env, aun sin Agent que lo consuma
  packet_mbx    gen_agnt_mbx;   // temporal: lo conecta el testbench, no el Test
  event         agnt_done;      // temporal: lo conecta el testbench, no el Test

  function new();
    gen0 = new();
  endfunction

  task run();
    // Wiring del Generator, justo antes de arrancarlo, con lo que
    // ya nos haya llegado (del Test y del testbench).
    gen0.tst_gen_mbx  = tst_gen_mbx;
    gen0.gen_agnt_mbx = gen_agnt_mbx;
    gen0.agnt_done    = agnt_done;

    fork
      gen0.run();
    join_none
  endtask
endclass

//////////////////////////////////////////////////////////////////
// test mismo codigo
//////////////////////////////////////////////////////////////////
class test;

  env e0; // enviroment instance
  cfg_mbx       tst_gen_mbx; // mailbox con generador
  escenario_mbx tst_agnt_mbx; // mailbox con agente

  function new ();
    e0 = new();
    tst_gen_mbx  = new();
    tst_agnt_mbx = new();

    //Conectar las mailbox
    e0.tst_gen_mbx  = tst_gen_mbx;
    e0.tst_agnt_mbx = tst_agnt_mbx;
  endfunction

  task run();
    cfg config_item;
    escenario esc_item;

    e0.run();                     // join_none interno, arranca el entorno/ambiente

    config_item = new();
    config_item.num       = 5;   // parametrizable, solo de inicializacion
    config_item.max_delay = 8;   // parametrizable, solo de inicializacion
    tst_gen_mbx.put(config_item);
    esc_item = new();

    tst_agnt_mbx.put(esc_item);
  endtask
endclass

///////////////// Prueba no es generacion propia //////////////////////

module test_bench;
  test       t0;
  packet_mbx pkt_mailbox;
  event      agnt_done;

  // Simula al Agent: recibe la transaccion, "la procesa" y avisa.
  task automatic fake_agent();
    packet item;
    forever begin
      pkt_mailbox.get(item);
      item.print("FakeAgent recibio");
      #5; // en el Agent real, aqui vendria la traduccion hacia el driver
      -> agnt_done;
    end
  endtask

  initial begin
    pkt_mailbox = new();

    t0 = new();                        // arma env + generator + sus mailboxes internos

    // Conexion TEMPORAL: en el proyecto real esto lo hace el Agent
    // (via env), no el testbench de nivel superior.
    t0.e0.gen_agnt_mbx = pkt_mailbox;
    t0.e0.agnt_done    = agnt_done;

    fork
      fake_agent();
    join_none

    t0.run();     // manda config y escenario, retorna casi de inmediato

    #100;         // le da tiempo al Generator (corriendo en paralelo) a terminar
    $display("Test_bench: fin de la prueba");
    $finish;
  end
endmodule
