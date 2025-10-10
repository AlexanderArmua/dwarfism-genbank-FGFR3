#!/usr/bin/perl
use strict; # Evita que se asignen valores a variables no declaradas
use warnings; # Muestra advertencias cuando se produce un error
use LWP::UserAgent; # Biblioteca que permite hacer peticiones HTTP
use HTTP::Request::Common; # Biblioteca que permite hacer peticiones HTTP
use Bio::SeqIO; # Biblioteca que permite leer y escribir secuencias en diferentes formatos.

# Crear user agent
my $ua = LWP::UserAgent->new; # Crear un objeto de la clase LWP::UserAgent
$ua->timeout(30); # Establecer el tiempo de espera en 30 segundos

my $file_name = $ARGV[0];
my $input_file_name = "fasta_files/$file_name.fasta";

# Leer archivo FASTA
my $seqio = Bio::SeqIO->new(-file => $input_file_name, -format => "fasta"); # Crear un objeto de la clase Bio::SeqIO
# -file: indica el archivo de entrada
# -format: indica el formato del archivo de entrada
# $seqio: objeto de la clase Bio::SeqIO que permite leer el archivo FASTA

while (my $seq = $seqio->next_seq) { # Leer la secuencia FASTA
    my $sequence = $seq->seq; # Obtener la secuencia
    my $seq_id = $seq->display_id; # Obtener el ID de la secuencia
    
    print "Enviando secuencia: $seq_id\n";
    
    # Enviar BLAST job:
    my $response = $ua->post('https://blast.ncbi.nlm.nih.gov/blast/Blast.cgi',
        {
            'CMD' => 'Put',
            'PROGRAM' => 'blastp',
            'DATABASE' => 'swissprot',
            'QUERY' => $sequence,
            'FORMAT_TYPE' => 'Text'
        }
    );
    
    if ($response->is_success) { # Si la respuesta es exitosa
        # Extraer RID (Request ID) de la respuesta
        my $content = $response->content; # Obtener el contenido de la respuesta
        if ($content =~ /RID = (\w+)/) { # Si el contenido contiene el RID
            my $rid = $1;
            print "Job enviado. RID: $rid\n";
            
            # Esperar y obtener resultados:
            sleep(10);  # Esperar 10 segundos
            
            my $get_response = $ua->post('https://blast.ncbi.nlm.nih.gov/blast/Blast.cgi', # Enviar BLAST job
                {
                    'CMD' => 'Get',
                    'RID' => $rid,
                    'FORMAT_TYPE' => 'Text'
                }
            );
            
            if ($get_response->is_success) { # Si la respuesta es exitosa
                # Guardar resultados
                use File::Path qw(make_path);
                make_path('results/remote_blast') unless -d 'results/remote_blast';
                open(my $out, ">", "results/remote_blast/blast_result_$seq_id.txt") or die "Cannot open file: $!";
                print $out $get_response->content;
                close($out);
                print "Resultados guardados en results/remote_blast/blast_result_$seq_id.txt\n";
            } else {
                print "Error obteniendo resultados: " . $get_response->status_line . "\n";
            }
        }
    } else {
        print "Error enviando BLAST: " . $response->status_line . "\n";
    }
    
    print "---\n";
}