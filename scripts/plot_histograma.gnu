# histograma de los retrasos, se corre despues de la simulacion:
#   gnuplot -e "archivo='sim/reporte.csv'" scripts/plot_histograma.gnu
# si no se pasa archivo usa reporte.csv de la carpeta actual

if (!exists("archivo")) archivo = "reporte.csv"
if (!exists("ancho"))   ancho = 50          # ancho de cada barra en ns

set datafile separator ","
set terminal png size 900,600
set output "histograma.png"

set title "Retraso de los paquetes recibidos"
set xlabel "retraso (ns)"
set ylabel "cantidad de paquetes"
set grid
set key off
set style fill solid 0.6

# las filas sin retraso (descartados) quedan vacias y gnuplot las salta
bin(x) = ancho * floor(x/ancho)
set boxwidth ancho

plot archivo using (bin($7)):(1.0) smooth freq with boxes
