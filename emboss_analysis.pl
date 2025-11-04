#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

# --- Configuración ---
my $OUTPUT_DIR = "emboss_results_clean";

# --- 1. Verificación de Inputs ---
my ($input_file) = @ARGV;

unless (@ARGV == 1) {
    die "Uso: perl emboss_analysis_fixed.pl <archivo.fasta>\n" .
        "Ejemplo: perl emboss_analysis_fixed.pl fasta_files/FGFR3_human.fasta\n";
}

unless (-f $input_file) {
    die "Error: No se pudo encontrar el archivo '$input_file'\n";
}

# Crear directorio de salida
system("mkdir -p $OUTPUT_DIR");

print "=== ANÁLISIS DE SECUENCIAS CON EMBOSS (VERSIÓN MEJORADA) ===\n";
print "Input: $input_file\n";
print "Output dir: $OUTPUT_DIR\n\n";

# --- 2. Limpiar secuencias problemáticas ---
print "1. Limpiando secuencias problemáticas...\n";
my $clean_file = "$OUTPUT_DIR/sequences_clean.fasta";

open(my $in_fh, '<', $input_file) or die "No se pudo abrir $input_file: $!\n";
open(my $out_fh, '>', $clean_file) or die "No se pudo crear $clean_file: $!\n";

my $sequence_count = 0;
my $current_header = "";
my $current_seq = "";

while (my $line = <$in_fh>) {
    chomp $line;
    
    if ($line =~ /^>(.+)/) {
        # Procesar secuencia anterior si existe
        if ($current_header && $current_seq) {
            process_sequence($current_header, $current_seq, $out_fh, \$sequence_count);
        }
        
        $current_header = $1;
        $current_seq = "";
    } else {
        $current_seq .= $line;
    }
}

# Procesar última secuencia
if ($current_header && $current_seq) {
    process_sequence($current_header, $current_seq, $out_fh, \$sequence_count);
}

close $in_fh;
close $out_fh;

print "   -> $sequence_count secuencias limpias guardadas en: $clean_file\n\n";

if ($sequence_count == 0) {
    die "Error: No se encontraron secuencias válidas después de la limpieza\n";
}

# --- 3. Análisis de estadísticas básicas ---
print "2. Calculando estadísticas de proteínas...\n";
my $stats_file = "$OUTPUT_DIR/protein_stats.txt";
system("pepstats -sequence $clean_file -outfile $stats_file -auto");
print "   -> Estadísticas guardadas en: $stats_file\n\n";

# --- 4. Análisis de composición (con parámetros automáticos) ---
print "3. Calculando composición de aminoácidos...\n";
my $comp_file = "$OUTPUT_DIR/amino_acid_composition.txt";
system("compseq -sequence $clean_file -outfile $comp_file -word 1 -auto");
print "   -> Composición guardada en: $comp_file\n\n";

# --- 5. Información básica de secuencias ---
print "4. Obteniendo información de secuencias...\n";
my $info_file = "$OUTPUT_DIR/sequence_info.txt";
system("infoseq -sequence $clean_file -outfile $info_file -auto");
print "   -> Información guardada en: $info_file\n\n";

# --- 6. Análisis de propiedades (sin gráficos) ---
print "5. Analizando propiedades fisicoquímicas...\n";
my $props_file = "$OUTPUT_DIR/physicochemical_properties.txt";
system("pepinfo -sequence $clean_file -outfile $props_file -graph none -auto");
print "   -> Propiedades guardadas en: $props_file\n\n";

# --- 7. Buscar motivos simples (sin PROSITE) ---
print "6. Buscando patrones de aminoácidos...\n";
my $patterns_file = "$OUTPUT_DIR/amino_patterns.txt";
system("pepwindowall -sequence $clean_file -outfile $patterns_file -auto");
print "   -> Patrones encontrados en: $patterns_file\n\n";

# --- 8. Generar reporte final ---
print "7. Generando reporte final...\n";
my $report_file = "$OUTPUT_DIR/analysis_report.txt";

open(my $report_fh, '>', $report_file) or die "No se pudo crear $report_file: $!\n";

print $report_fh "=== REPORTE DE ANÁLISIS EMBOSS (VERSIÓN LIMPIA) ===\n";
print $report_fh "Fecha: " . localtime() . "\n";
print $report_fh "Archivo input original: $input_file\n";
print $report_fh "Archivo limpio procesado: $clean_file\n";
print $report_fh "Secuencias válidas procesadas: $sequence_count\n\n";

print $report_fh "ARCHIVOS GENERADOS:\n";
print $report_fh "- Secuencias limpias: $clean_file\n";
print $report_fh "- Estadísticas de proteínas: $stats_file\n";
print $report_fh "- Composición de aminoácidos: $comp_file\n";
print $report_fh "- Información de secuencias: $info_file\n";
print $report_fh "- Propiedades fisicoquímicas: $props_file\n";
print $report_fh "- Patrones de aminoácidos: $patterns_file\n\n";

print $report_fh "DESCRIPCIÓN DE ANÁLISIS REALIZADOS:\n";
print $report_fh "1. Limpieza de secuencias - Remoción de caracteres inválidos\n";
print $report_fh "2. pepstats - Estadísticas básicas de las secuencias\n";
print $report_fh "3. compseq - Composición de aminoácidos\n";
print $report_fh "4. infoseq - Información general de secuencias\n";
print $report_fh "5. pepinfo - Propiedades fisicoquímicas\n";
print $report_fh "6. pepwindowall - Análisis de patrones locales\n\n";

print $report_fh "PROBLEMAS SOLUCIONADOS:\n";
print $report_fh "- Remoción de caracteres inválidos (*, X, B, Z, U)\n";
print $report_fh "- Filtrado de secuencias muy cortas (<10 aa)\n";
print $report_fh "- Parámetros automáticos para evitar prompts interactivos\n";
print $report_fh "- Análisis sin dependencias de PROSITE\n";

close $report_fh;

print "   -> Reporte completo en: $report_file\n\n";

print "=== ANÁLISIS COMPLETADO EXITOSAMENTE ===\n";
print "Todos los resultados están en el directorio: $OUTPUT_DIR/\n";
print "Archivo principal de resultados: $report_file\n";

# --- Subrutina para procesar y limpiar secuencias ---
sub process_sequence {
    my ($header, $seq, $out_fh, $count_ref) = @_;
    
    # Limpiar secuencia
    $seq = uc($seq);                    # Convertir a mayúsculas
    $seq =~ s/[^ACDEFGHIKLMNPQRSTVWY]//g; # Remover caracteres inválidos
    $seq =~ s/\s+//g;                   # Remover espacios
    
    # Solo procesar secuencias de al menos 10 aminoácidos
    if (length($seq) >= 10) {
        print $out_fh ">$header\n";
        
        # Escribir secuencia en líneas de 80 caracteres
        my $pos = 0;
        while ($pos < length($seq)) {
            my $line = substr($seq, $pos, 80);
            print $out_fh "$line\n";
            $pos += 80;
        }
        
        $$count_ref++;
    }
}
