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

typedef mailbox #(packet) packet_mbx;
typedef mailbox #(cfg)    cfg_mbx;

//////////////////////////////////////////////////////////////////
// generator
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

//////////////////////////////////////////////////////////////////
// Testbench de aislamiento: hace de Test (manda config UNA vez) y
// de Agent (consume transacciones y avisa agnt_done).
//////////////////////////////////////////////////////////////////

module test_bench;
  generator  gen;
  cfg_mbx    cfg_mailbox;
  packet_mbx pkt_mailbox;
  event      agnt_done;

  // Simula al Test: arma la config y la manda una sola vez.
  task automatic fake_test();
    cfg config_item = new();
    config_item.num       = 5;
    config_item.max_delay = 8;
    cfg_mailbox.put(config_item);
  endtask

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
    cfg_mailbox = new();
    pkt_mailbox = new();

    gen = new();
    gen.tst_gen_mbx  = cfg_mailbox;
    gen.gen_agnt_mbx = pkt_mailbox;
    gen.agnt_done    = agnt_done;

    // fake_agent es "forever": lo lanzamos en background y lo
    // dejamos vivo. fake_test solo pone un mensaje y termina.
    fork
      fake_test();
      fake_agent();
    join_none

    // gen.run() corre en ESTE proceso: bloquea hasta terminar
    // sus 5 items, que es justo cuando queremos seguir.
    gen.run();

    #20;
    $finish;
  end
endmodule
