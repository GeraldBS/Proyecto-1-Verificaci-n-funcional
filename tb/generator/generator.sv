class generator;
 cfg_mbx      tst_gen_mbx;    // config, viene del Test
 packet_mbx   gen_agnt_mbx;   // transaction, va hacia el Agent
 event        agnt_done;      // el Agent avisa cuando ya proceso el item


 int num; // parametrizable
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

// consideraciones: