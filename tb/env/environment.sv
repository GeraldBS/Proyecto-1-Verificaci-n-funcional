//////////////////////////////////////////////////////////////////////
// env: junta los bloques del ambiente y los conecta                //
//////////////////////////////////////////////////////////////////////
// Por ahora tiene generator y el manejador (agent_drv).
// Cuando esten listos aqui entran tambien monitor, checker y
// scoreboard.
//
//   test --cfg--> generator --packet--> agent_drv --> DUT
//                                           |
//                                           +--packet--> checker
//////////////////////////////////////////////////////////////////////

class env;

  virtual bus_if vif;

  generator gen0;
  agent_drv agnt_drv0;

  cfg_mbx       tst_gen_mbx;   // del test al generator
  escenario_mbx tst_agnt_mbx;  // del test al agente (todavia no se usa)

  packet_mbx gen_agnt_mbx;     // generator -> agente
  packet_mbx drv_chkr_mbx;     // driver -> checker

  int profundidad = 8;         // tamano de las fifos emuladas

  function new();
    gen0      = new();
    agnt_drv0 = new();

    // estos mailboxes son internos del ambiente
    gen_agnt_mbx = new();
    drv_chkr_mbx = new();
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

    fork
      gen0.run();
      agnt_drv0.run();
    join_none
  endtask

endclass
