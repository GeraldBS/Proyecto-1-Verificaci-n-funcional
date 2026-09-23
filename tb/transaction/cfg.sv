//////////////////////////////////////////////////////////////////////
// cfg: configuracion que el test le manda al generator            //
// escenario: instruccion que el test le manda al agente           //
//////////////////////////////////////////////////////////////////////
// El numero de transacciones de cada terminal se aleatoriza aqui, con
// un minimo y un maximo que pone el test, asi cada terminal manda una
// cantidad distinta y el trafico queda desbalanceado.
// Todo esto se puede cambiar sin recompilar.
//////////////////////////////////////////////////////////////////////
`include "parametros.svh"

class cfg;

  rand int trans_x_terminal[`DRVRS]; // cuántas manda cada terminal

  int min_trans = 1;   // mínimo por terminal
  int max_trans = 10;  // máximo por terminal

  int max_delay = 10;  // ciclos máximos de espera
  int min_delay = 0;

  // porcentaje de cada tipo de envío
  int peso_normal    = 80;
  int peso_broadcast = 10;
  int peso_error     = 10;
  int peso_propio    = 0;

  constraint c_trans {
    foreach (trans_x_terminal[i])
      trans_x_terminal[i] inside {[min_trans:max_trans]};
  }

  function int total();   // la suma de todas las terminales
    int t = 0;
    foreach (trans_x_terminal[i]) t += trans_x_terminal[i];
    return t;
  endfunction

  function void print(string tag = "");
    $display("[%0t] %s total=%0d delay=[%0d:%0d] pesos=%0d/%0d/%0d/%0d",
             $time, tag, total(), this.min_delay, this.max_delay,
             this.peso_normal, this.peso_broadcast,
             this.peso_error, this.peso_propio);
    foreach (trans_x_terminal[i])
      $display("      terminal %0d manda %0d", i, trans_x_terminal[i]);
  endfunction

endclass

// que secuencia debe correr el agente
typedef enum {esc_aleatorio, esc_todos_a_uno, esc_broadcast, esc_esquina} tipo_escenario;

class escenario;
  tipo_escenario tipo = esc_aleatorio;
endclass
