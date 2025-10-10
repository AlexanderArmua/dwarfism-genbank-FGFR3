#!/usr/bin/perl
use strict;
use warnings;

# Script para extraer un ORF específico de un archivo FASTA y guardarlo en un nuevo archivo.
#
# Uso: perl extract_orf.pl <nombre> <orf>
# Ejemplo: perl extract_orf.pl FGFR3_human ORF_plus_2

sub extract_orf {
    my ($name, $orf) = @_;

    # Construir rutas de archivos
    my $input_file = "fasta_files/$name.fasta";
    my $output_file = "fasta_files/${name}_${orf}.fasta";

    # Verificar que el archivo de entrada existe
    unless (-e $input_file) {
        die "Error: El archivo $input_file no existe.\n";
    }

    # Abrir archivo de entrada
    open(my $in_fh, '<', $input_file) or die "No se pudo abrir $input_file: $!\n";

    # Leer todo el archivo
    my @lines = <$in_fh>;
    close($in_fh);

    # Buscar el ORF específico
    my $orf_found = 0;
    my @orf_content;

    for (my $i = 0; $i < scalar(@lines); $i++) {
        my $line = $lines[$i];

        # Si encontramos el header del ORF que buscamos
        if ($line =~ /^>/ && $line =~ /$orf/) {
            $orf_found = 1;
            push @orf_content, $line;

            # Agregar todas las líneas siguientes hasta el próximo header
            for (my $j = $i + 1; $j < scalar(@lines); $j++) {
                if ($lines[$j] =~ /^>/) {
                    last;
                }
                push @orf_content, $lines[$j];
            }
            last;
        }
    }

    unless ($orf_found) {
        die "Error: El ORF '$orf' no fue encontrado en $input_file\n";
    }

    # Escribir el contenido al archivo de salida
    open(my $out_fh, '>', $output_file) or die "No se pudo crear $output_file: $!\n";
    print $out_fh @orf_content;
    close($out_fh);

    print "ORF '$orf' extraído exitosamente.\n";
    print "Archivo de salida: $output_file\n";
}

# Main
if (@ARGV != 2) {
    print "Uso: perl extract_orf.pl <nombre> <orf>\n";
    print "Ejemplo: perl extract_orf.pl FGFR3_human ORF_plus_2\n";
    exit(1);
}

my $name = $ARGV[0];
my $orf = $ARGV[1];

extract_orf($name, $orf);
