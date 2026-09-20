//////////////////////////////////////////////////////////////////////
// env: junta los bloques del ambiente y los conecta                //
//////////////////////////////////////////////////////////////////////
// Tiene generator, el manejador (agent_drv) y ahora el vigilante
// (agent_mon). Cuando esten listos aqui entran tambien checker y
// scoreboard.
//
//   test --cfg--> generator --packet--> agent_drv --> DUT --> agent_mon --pckg_mon--> checker
//                                           |
//                                           +--packet--> checker (via scoreboard, pendiente)
//////////////////////////////////////////////////////////////////////

class env;

  virtual bus_if vif;

  generator gen0;
  agent_drv agnt_drv0;
  agent_mon agnt_mon0;

  cfg_mbx       tst_gen_mbx;   // del test al generator
  escenario_mbx tst_agnt_mbx;  // del test al agente (todavia no se usa)

  packet_mbx   gen_agnt_mbx;   // generator -> agente
  packet_mbx   drv_chkr_mbx;   // driver -> checker (pasara por el scoreboard)
  pckg_mon_mbx mon_chkr_mbx;   // agent_mon -> checker

  int profundidad = 8;         // tamano de las fifos emuladas

  function new();
    gen0      = new();
    agnt_drv0 = new();
    agnt_mon0 = new();

    // estos mailboxes son internos del ambiente
    gen_agnt_mbx = new();
    drv_chkr_mbx = new();
    mon_chkr_mbx = new();
  endfunction

  task run();
    // conecta el generator
    gen0.tst_gen_mbx  = tst_gen_mbx;
    gen0.gen_agnt_mbx = gen_agnt_mbx;

    // conecta el manejador
    agnt_drv0.vif          = vif;
    agnt_drv0.gen_agnt_mbx = gen_agnt_mbx;
    agnt_drv0.drv_chkr_mbx = drv_chkr_mbx;
    agnt_drv0.profundidad  = profundidad;

    // conecta el vigilante
    agnt_mon0.vif          = vif;
    agnt_mon0.mon_chkr_mbx = mon_chkr_mbx;

    fork
      gen0.run();
      agnt_drv0.run();
      agnt_mon0.run();
    join_none
  endtask

endclass
