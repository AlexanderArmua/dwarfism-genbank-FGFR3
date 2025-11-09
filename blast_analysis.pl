#!/usr/bin/perl

# Activamos el modo estricto y las advertencias
use strict;
use warnings;

# --- Para el Punto Extra ---
# Importamos los módulos de BioPerl necesarios
use Bio::DB::SwissProt;
use Bio::SeqIO;

# --- 1. Verificación de Inputs ---

# El script espera 2 argumentos: el archivo BLAST y el patrón de búsqueda
my ($blast_file, $pattern) = @ARGV;

# Si no se proveen 2 argumentos, muestra cómo usar el script y termina.
unless (@ARGV == 2) {
    die "Uso: perl ex4.pl <archivo_blast.out> <'Patron de busqueda'>\n" .
        "Ejemplo: perl ex4.pl results/blast_local_with_desc.out 'Homo sapiens'\n";
}

print "Buscando hits que contengan '$pattern' en '$blast_file'...\n\n";

# --- 2. Parseo del Archivo BLAST ---

# Abrimos el archivo de reporte BLAST (solo lectura)
open(my $fh, '<', $blast_file) or die "Error: No se pudo abrir $blast_file: $!\n";

my %accessions_to_fetch; # Hash para guardar los IDs (Punto Extra)

print "--- Hits Encontrados ---\n";

# Leemos el archivo línea por línea
while (my $line = <$fh>) {
    # Ignoramos líneas de comentario (aunque outfmt 6 no suele tenerlas)
    next if $line =~ /^#/;
    
    # Quitamos el salto de línea final
    chomp $line;
    
    # Dividimos la línea por el tabulador (\t)
    # Formato esperado (13 columnas):
    # 0:qseqid 1:sseqid 2:pident ... 11:bitscore 12:stitle
    my @cols = split(/\t/, $line);
    
    # Asegurarnos de que la línea tenga la columna de descripción
    unless (defined $cols[12]) {
        print "Advertencia: Línea mal formada (sin columna 13 'stitle'), saltando.\n";
        next;
    }
    
    my $accession   = $cols[1];  # 'sseqid' (ej. P22607.1)
    my $description = $cols[12]; # 'stitle' (ej. Fibroblast growth factor receptor 3 OS=Homo sapiens ...)
    
    # Comparamos la descripción con el patrón (case-insensitive)
    if ($description =~ /$pattern/i) {
        
        # --- Output Principal ---
        # Imprimimos la línea completa del hit que coincidió
        print "$line\n";
        
        # --- Punto Extra ---
        # Guardamos el accession para descargarlo luego
        $accessions_to_fetch{$accession} = 1;
    }
}

close $fh;
print "------------------------\n\n";

# --- 3. Implementación del Punto Extra ---

# Verificamos si encontramos hits para descargar
if (scalar keys %accessions_to_fetch > 0) {
    
    print "--- Punto Extra: Descargando secuencias FASTA ---\n";
    
    my $output_fasta = 'results/hits_seleccionados.fasta';
    
    # Inicializamos la conexión a GenBank (NCBI)
    my $sp_conn = Bio::DB::SwissProt->new();

    # Inicializamos el objeto para escribir el archivo FASTA de salida
    my $seq_out = Bio::SeqIO->new(
        -file   => ">$output_fasta",
        -format => 'Fasta'
    );
    
    foreach my $acc (keys %accessions_to_fetch) {
        print "Intentando descargar: $acc\n";
        
        # ADVERTENCIA:
        # Tu BLAST fue contra SwissProt (UniProt)[cite: 46]. Los IDs (ej. P22607.1) 
        # son de UniProt. Bio::DB::GenBank busca en NCBI (GenBank).
        # A veces los IDs coinciden o NCBI los reconoce, pero si no, esta
        # parte puede fallar al no encontrar el ID.
        
        eval {
            # Intentamos obtener la secuencia por su ID de acceso
            my $seq_obj = $sp_conn->get_Seq_by_acc($acc);
            
            if ($seq_obj) {
                # Si se encuentra, la escribimos en el archivo FASTA
                $seq_out->write_seq($seq_obj);
                print "  -> Éxito. Guardado en $output_fasta\n";
            } else {
                print "  -> Advertencia: No se encontró el ID '$acc' en GenBank.\n";
            }
        };
        # Manejamos cualquier error de red o de la librería
        if ($@) {
            print "  -> Error al procesar $acc: $@\n";
        }
    }
    
    print "Proceso de descarga completado.\n";
} else {
    print "No se encontraron hits que coincidieran con '$pattern' para el punto extra.\n";
}