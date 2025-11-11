#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

my $OUTPUT_DIR = "emboss_results";

my ($input_file) = @ARGV;

unless (@ARGV == 1) {
    die "Uso: perl emboss_analysis_fixed.pl <archivo.fasta>\n" .
        "Ejemplo: perl emboss_analysis_fixed.pl fasta_files/FGFR3_human.fasta\n";
}

unless (-f $input_file) {
    die "Error: No se pudo encontrar el archivo '$input_file'\n";
}

system("mkdir -p $OUTPUT_DIR");

print "=== ANÁLISIS DE SECUENCIAS CON EMBOSS ===\n";
print "Input: $input_file\n";
print "Output dir: $OUTPUT_DIR\n\n";

print "Limpiando secuencias problemáticas...\n";
my $clean_file = "$OUTPUT_DIR/sequences_clean.fasta";

open(my $in_fh, '<', $input_file) or die "No se pudo abrir $input_file: $!\n";
open(my $out_fh, '>', $clean_file) or die "No se pudo crear $clean_file: $!\n";

my $sequence_count = 0;
my $current_header = "";
my $current_seq = "";

while (my $line = <$in_fh>) {
    chomp $line;
    
    if ($line =~ /^>(.+)/) {
        if ($current_header && $current_seq) {
            process_sequence($current_header, $current_seq, $out_fh, \$sequence_count);
        }
        
        $current_header = $1;
        $current_seq = "";
    } else {
        $current_seq .= $line;
    }
}

if ($current_header && $current_seq) {
    process_sequence($current_header, $current_seq, $out_fh, \$sequence_count);
}

close $in_fh;
close $out_fh;

print "   -> $sequence_count secuencias limpias guardadas en: $clean_file\n\n";

if ($sequence_count == 0) {
    die "Error: No se encontraron secuencias válidas después de la limpieza\n";
}

print "1. Calculando estadísticas de proteínas...\n";
my $stats_file = "$OUTPUT_DIR/protein_stats.txt";
system("pepstats -sequence $clean_file -outfile $stats_file -auto");
print "   -> Estadísticas guardadas en: $stats_file\n\n";

print "2. Calculando composición de aminoácidos...\n";
my $comp_file = "$OUTPUT_DIR/amino_acid_composition.txt";
system("compseq -sequence $clean_file -outfile $comp_file -word 1 -auto");
print "   -> Composición guardada en: $comp_file\n\n";

print "3. Obteniendo información de secuencias...\n";
my $info_file = "$OUTPUT_DIR/sequence_info.txt";
system("infoseq -sequence $clean_file -outfile $info_file -auto");
print "   -> Información guardada en: $info_file\n\n";

print "4. Analizando propiedades fisicoquímicas...\n";
my $props_file = "$OUTPUT_DIR/physicochemical_properties.txt";
system("pepinfo -sequence $clean_file -outfile $props_file -graph none -auto");
print "   -> Propiedades guardadas en: $props_file\n\n";

print "5. Buscando patrones de aminoácidos...\n";
my $patterns_file = "$OUTPUT_DIR/amino_patterns";
system("pepwindowall -sequence $clean_file -graph svg -goutfile $patterns_file");
print "   -> Patrones encontrados en: $patterns_file\n\n";

print "6. Generando reporte final...\n";
my $report_file = "$OUTPUT_DIR/analysis_report.txt";

open(my $report_fh, '>', $report_file) or die "No se pudo crear $report_file: $!\n";

print $report_fh "=== REPORTE DE ANÁLISIS EMBOSS===\n";
print $report_fh "Archivo input original: $input_file\n";
print $report_fh "Secuencias válidas procesadas: $sequence_count\n\n";

print $report_fh "1. pepstats - Estadísticas de proteínas: $stats_file\n";
print $report_fh "2. compseq - Composición de aminoácidos: $comp_file\n";
print $report_fh "3. infoseq - Información de secuencias: $info_file\n";
print $report_fh "4. pepinfo - Propiedades fisicoquímicas: $props_file\n";
print $report_fh "5. pepwindowall - Análisis de patrones de aminoácidos $patterns_file.png\n\n";

close $report_fh;

print "   -> Reporte completo en: $report_file\n\n";

print "Todos los resultados están en el directorio: $OUTPUT_DIR/\n";
print "Archivo principal de resultados: $report_file\n";

sub process_sequence {
    my ($header, $seq, $out_fh, $count_ref) = @_;
    
    $seq = uc($seq);                    # Uppercase
    $seq =~ s/[^ACDEFGHIKLMNPQRSTVWY]//g; # Sacar caracteres inválidos
    $seq =~ s/\s+//g;                   # Sacar espacios
    
    # Sacamos las secuencias con menos de 10 aminoácidos
    if (length($seq) >= 10) {
        print $out_fh ">$header\n";

        my $pos = 0;
        while ($pos < length($seq)) {
            my $line = substr($seq, $pos, 80);
            print $out_fh "$line\n";
            $pos += 80;
        }
        
        $$count_ref++;
    }
}
