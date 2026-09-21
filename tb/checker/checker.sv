//////////////////////////////////////////////////////////////////////
// checker: compara lo que vio el monitor contra el scoreboard      //
//////////////////////////////////////////////////////////////////////
// Por cada pckg_mon que llega del monitor le pide al scoreboard el
// registro que le calza. Si no hay ninguno, es una recepcion que
// nadie esperaba y se reporta como error.
//////////////////////////////////////////////////////////////////////

// OJO: "checker" es palabra reservada de SystemVerilog
// (existe el bloque checker/endchecker), por eso la clase se llama
// chequeador aunque el archivo y el bloque se sigan llamando checker.
class chequeador;

  pckg_mon_mbx mon_chkr_mbx;  // del monitor
  scoreboard   sb;

  int vistos      = 0;
  int sin_esperar = 0;

  task run();
    pckg_mon m;
    forever begin
      mon_chkr_mbx.get(m);
      vistos++;
      if (!sb.emparejar(m)) begin
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
