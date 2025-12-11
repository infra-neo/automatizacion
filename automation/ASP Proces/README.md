Ejecucion diaria
Server origen : 100.118.17.128
Server destino: 100.64.161.120
URl token:  "https://api.caradhras.io/morpheus/v1/query"
$Variable Fecha inicio: "2025-10-24T01:00:00.000\"
$Variable Fecha fin: "2025-11-13T06:00:00.000\"
cert /home/erangel/certificate.pem
key /home/erangel/certificate.key
Directorio trabajo /home/erangel/sftpdocks/movimientos_diarios
    crear carpeta por cada dia con la fecha y depositar en este directorio el archivo
Acceder al sftp de dock en la carpeta de /product/morpheus/[fecha]
con sftp get traer el archivo 
// posible nombre del archivo "Localizar el csv (MORPHEUS_GLOBAL_ENTRY_[clave DOCK]_[fecha]_[tiempo].zip)  generado recientemente" //
Descargar el archivo

Enviarlo al área de datos desde el servidor a un correo electronico.

