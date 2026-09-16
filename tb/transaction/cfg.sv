//////////////////////////////////////////////////////////////////////
// cfg: configuracion que el test le manda al generator            //
// escenario: instruccion que el test le manda al agente           //
//////////////////////////////////////////////////////////////////////
// Mantiene num y max_delay con los mismos nombres que ya usa el
// generator, y agrega lo que hace falta para el proyecto.
// Todo esto se puede cambiar sin recompilar (ver base_test).
//////////////////////////////////////////////////////////////////////

class cfg;
  int num       = 5;   // transacciones por terminal
  int max_delay = 10;  // ciclos maximos de espera
  int min_delay = 0;

  // porcentaje de cada tipo de envio
  int peso_normal    = 80;
  int peso_broadcast = 10;
  int peso_error     = 10;
  int peso_propio    = 0;

  function void print(string tag = "");
    $display("[%0t] %s num=%0d delay=[%0d:%0d] pesos=%0d/%0d/%0d/%0d",
             $time, tag, this.num, this.min_delay, this.max_delay,
             this.peso_normal, this.peso_broadcast,
             this.peso_error, this.peso_propio);
  endfunction
endclass

// que secuencia debe correr el agente
typedef enum {esc_aleatorio, esc_todos_a_uno, esc_broadcast, esc_esquina} tipo_escenario;

class escenario;
  tipo_escenario tipo = esc_aleatorio;
endclass
