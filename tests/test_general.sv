class test;

 env e0; // enviroment instance
 cfg_mbx       tst_gen_mbx; // mailbox con generador
 escenario_mbx tst_agnt_mbx; // mailbox con agente

 function new ();
  e0 = new();
  tst_gen_mbx  = new();
  tst_agnt_mbx = new();

  //Conectar las mailbox
  e0.tst_gen_mbx = tst_gen_mbx;
  e0.tst_agnt_mbx = tst_agnt_mbx;
 endfunction


 task run();
  cfg config_item;
  escenario esc_item;      

  e0.run();                 // join_none interno, arranca el entorno/ambiente

  config_item = new();
  config_item.num       = 5;   // parametrizable, solo de inicializacion
  config_item.max_delay = 8;   // parametrizable, solo de inicializacion
  tst_gen_mbx.put(config_item);  
  esc_item = new();
  
  tst_agnt_mbx.put(esc_item);
 endtask
endclass