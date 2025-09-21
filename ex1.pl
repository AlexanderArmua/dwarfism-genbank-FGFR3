#!/usr/bin/perl
use strict; # Evita que se asignen valores a variables no declaradas
use warnings; # Muestra advertencias cuando se produce un error
use Bio::SeqIO; # Biblioteca que permite leer y escribir secuencias en diferentes formatos.

# Descripción del código:
# Este código lee un archivo GenBank y genera tres marcos directos y tres marcos reversos de la secuencia del gen FGFR3.

# Inicialización de la biblioteca Bio::SeqIO
# Bio::SeqIO es una biblioteca que permite leer y escribir secuencias en diferentes formatos.
# En este caso, se utiliza para leer el archivo GenBank y escribir el archivo FASTA.
# -file: indica el archivo de entrada
# -format: indica el formato del archivo de entrada
# $input: objeto de la clase Bio::SeqIO que permite leer el archivo GenBank
# $output: objeto de la clase Bio::SeqIO que permite escribir el archivo FASTA

# Input GenBank:
my $input = Bio::SeqIO->new(-file => "FGFR3.gbk", -format => "genbank");
# Output FASTA:
my $output = Bio::SeqIO->new(-file => ">FGFR3_orfs.fasta", -format => "fasta");

while (my $seq_obj = $input->next_seq) {
    # 3 marcos directos:
    for my $frame (0..2) {
        # Se traduce la secuencia del gen en el marco directo.
        # -frame: indica el marco de lectura
        # $aa: objeto de la clase Bio::Seq que permite traducir la secuencia del gen en el marco directo
        # $aa->display_id: indica el nombre del gen en el archivo FASTA
        # $output->write_seq: escribe la secuencia traducida en el archivo FASTA
        my $aa = $seq_obj->translate(-frame => $frame);
        # $aa->display_id: indica el nombre del gen en el archivo FASTA
        # $output->write_seq: escribe la secuencia traducida en el archivo FASTA
        $aa->display_id("ORF_plus_$frame");
        # $output->write_seq: escribe la secuencia traducida en el archivo FASTA
        $output->write_seq($aa);
    }
    # 3 marcos reversos:
    for my $frame (0..2) {
        # Se traduce la secuencia del gen en el marco reverso.
        # -frame: indica el marco de lectura
        # $rev: objeto de la clase Bio::Seq que permite traducir la secuencia del gen en el marco reverso
        # $rev->display_id: indica el nombre del gen en el archivo FASTA
        # $output->write_seq: escribe la secuencia traducida en el archivo FASTA
        my $rev = $seq_obj->revcom->translate(-frame => $frame);
        # $rev->display_id: indica el nombre del gen en el archivo FASTA
        # $output->write_seq: escribe la secuencia traducida en el archivo FASTA
        $rev->display_id("ORF_minus_$frame");
        # $output->write_seq: escribe la secuencia traducida en el archivo FASTA
        $output->write_seq($rev);
    }
}