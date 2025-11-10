#!/usr/bin/perl

use strict;
use warnings;
use Bio::DB::GenPept;
use Bio::SeqIO;

my ($blast_file, $pattern) = @ARGV;
unless (@ARGV == 2) {
    die "Uso: perl blast_analysis.pl <archivo_blast.out> <'Patron de busqueda'>\n" .
        "Ejemplo: perl blast_analysis.pl results/blast_local.out 'Homo sapiens'\n";
}

print "Buscando hits que contengan '$pattern' en '$blast_file'...\n\n";

open(my $fh, '<', $blast_file) or die "Error: No se pudo abrir $blast_file: $!\n";
my %accessions_to_fetch; # Hash para guardar los IDs (Punto Extra)
print "--- Hits Encontrados ---\n";
while (my $line = <$fh>) {
    next if $line =~ /^#/;
    chomp $line;
    my @cols = split(/\t/, $line);
    unless (defined $cols[12]) {
        print "Advertencia: Línea mal formada (sin columna 13 'stitle'), saltando.\n";
        next;
    }
    
    my $accession   = $cols[1];  # (ej. P22607.1)
    my $description = $cols[12]; # (ej. Fibroblast growth factor receptor 3 OS=Homo sapiens ...)
    
    if ($description =~ /$pattern/i) {
        print "$line\n";
        $accessions_to_fetch{$accession} = 1;
    }
}

close $fh;
print "------------------------\n\n";

if (scalar keys %accessions_to_fetch > 0) {
    
    print "--- Descargando secuencias FASTA ---\n";
    
    my $output_fasta = 'results/blast_analysis_results.fasta';
    my $gb_conn = Bio::DB::GenPept->new();
    my $seq_out = Bio::SeqIO->new(
        -file   => ">$output_fasta",
        -format => 'Fasta'
    );
    
    foreach my $acc (keys %accessions_to_fetch) {
        print "Intentando descargar: $acc\n";
        eval {
            my $seq_obj = $gb_conn->get_Seq_by_acc($acc);
            
            if ($seq_obj) {
                $seq_out->write_seq($seq_obj);
                print "  -> Éxito. Guardado en $output_fasta\n";
            } else {
                print "  -> Advertencia: No se encontró el ID '$acc' en GenBank.\n";
            }
        };
        if ($@) {
            print "  -> Error al procesar $acc: $@\n";
        }
    }
    print "Proceso de descarga completado.\n";
} else {
    print "No se encontraron hits que coincidieran con '$pattern'.\n";
}