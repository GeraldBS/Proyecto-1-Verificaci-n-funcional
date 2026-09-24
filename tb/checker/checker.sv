//////////////////////////////////////////////////////////////////////
// checker: compara lo que vio el monitor contra el scoreboard      //
//////////////////////////////////////////////////////////////////////
// Por cada pckg_mon que llega del monitor le pide al scoreboard el
// registro que le calza. Si no hay ninguno, es una recepcion que
// nadie esperaba y se reporta como error.
//////////////////////////////////////////////////////////////////////

class chequeador;

  pckg_mon_mbx mon_chkr_mbx;  // del monitor
  scoreboard   sb;

  int vistos      = 0;
  int sin_esperar = 0;

  task run();
    pckg_mon m;
    forever begin
      mon_chkr_mbx.get(m); // extraemos dato del monitor
      vistos++;
      if (!sb.emparejar(m)) begin // comparamos
        sin_esperar++;
        m.print("checker: ERROR nadie esperaba esta recepcion");
      end
    end
  endtask

  function void reporte();
    $display("---- checker ----");
    $display("recepciones vistas       : %0d", vistos);
    $display("recepciones inesperadas  : %0d", sin_esperar);
  endfunction

  function int errores();
    return sin_esperar + sb.perdidos();
  endfunction

endclass
