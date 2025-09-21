# Análisis Bioinformático del Gen FGFR3 - Achondroplasia

## 📋 Descripción del Proyecto

Este proyecto realiza un análisis bioinformático completo del gen **FGFR3** (Fibroblast Growth Factor Receptor 3) relacionado con la **achondroplasia** (enanismo). El análisis incluye traducción de marcos de lectura, búsquedas BLAST y alineamiento múltiple de secuencias.

### 🎯 Objetivos
- Analizar el gen FGFR3 asociado con achondroplasia
- Identificar marcos de lectura abiertos (ORFs)
- Realizar búsquedas de similitud con BLAST
- Encontrar proteínas homólogas en bases de datos públicas

## 🗂️ Estructura del Proyecto

```
bioinformatica/
├── FGFR3.gbk              # Archivo GenBank original
├── FGFR3_orfs.fasta       # ORFs traducidos (6 marcos)
├── Ex1.pl                 # Script de traducción de ORFs
├── Ex2_remote.pl          # Script BLAST remoto
├── blast_local.out        # Resultados BLAST local
├── blast_result_*.txt     # Resultados BLAST remoto
└── README.md              # Este archivo
```

## 🔧 Instalación de Dependencias

### 1. Instalar BioPerl
```bash
# Agregar repositorio de bioinformática
brew tap brewsci/bio

# Instalar BioPerl
brew install bioperl

# Configurar variables de entorno
echo 'export PERL5LIB="/opt/homebrew/Cellar/bioperl/1.7.8_2/libexec/lib/perl5:$PERL5LIB"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Instalar herramientas adicionales
```bash
# Instalar BLAST+
brew install blast

# Instalar cpanminus
curl -L https://cpanmin.us | perl - --sudo App::cpanminus
echo 'export PATH="/opt/homebrew/Cellar/perl/5.40.2/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Instalar módulos Perl adicionales
cpanm LWP::UserAgent
cpanm HTTP::Request::Common
```

## 🚀 Uso del Proyecto

### Paso 1: Generar ORFs
```bash
# Convertir GenBank a FASTA con 6 marcos de lectura
perl Ex1.pl
```
**Output:** `FGFR3_orfs.fasta` con 6 secuencias de proteínas

### Paso 2A: BLAST Remoto (Opcional)
```bash
# Ejecutar BLAST remoto contra SwissProt
perl Ex2_remote.pl
```
**Output:** 6 archivos `blast_result_ORF_*.txt`

### Paso 2B: BLAST Local (Recomendado)
```bash
# Descargar base de datos SwissProt
curl -O ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/swissprot.gz
gunzip swissprot.gz

# Crear base de datos local
makeblastdb -in swissprot -dbtype prot -out swissprot_db

# Ejecutar BLAST local
blastp -db swissprot_db -query FGFR3_orfs.fasta -out blast_local.out -outfmt 6 -evalue 1e-5 -max_target_seqs 10
```

## 📊 Interpretación de Resultados

### Archivos FASTA generados
- **FGFR3_orfs.fasta**: Contiene 6 secuencias de proteínas traducidas
  - `ORF_plus_0`, `ORF_plus_1`, `ORF_plus_2`: Marcos directos
  - `ORF_minus_0`, `ORF_minus_1`, `ORF_minus_2`: Marcos reversos

### Resultados BLAST
- **Identities**: Porcentaje de aminoácidos idénticos (mayor % = mejor)
- **E-value**: Significancia estadística (menor = mejor)
- **Score**: Calidad del alineamiento (mayor = mejor)
- **Positives**: Similitudes funcionales

### Valores de referencia
- **E-value < 1e-10**: Resultados muy confiables
- **Identities > 70%**: Alta similitud
- **Score > 100**: Alineamiento de buena calidad

## 🔧 Problemas Comunes y Soluciones

### Error: "Can't locate Bio/SeqIO.pm"
```bash
# Verificar instalación de BioPerl
find /opt/homebrew -name "SeqIO.pm" -type f 2>/dev/null

# Reconfigurar PERL5LIB
export PERL5LIB="/opt/homebrew/Cellar/bioperl/1.7.8_2/libexec/lib/perl5:$PERL5LIB"
```

### Error: "cpanm command not found"
```bash
# Buscar ubicación de cpanm
find /opt /usr -name "cpanm" 2>/dev/null

# Usar ruta completa o agregar al PATH
/opt/homebrew/Cellar/perl/5.40.2/bin/cpanm [módulo]
```

### BLAST remoto lento o falla
- **Solución**: Usar BLAST local (Paso 2B)
- **Causa**: Servidores NCBI sobrecargados
- **Alternativa**: Dividir archivo FASTA en secuencias más pequeñas

### Base de datos SwissProt muy grande
```bash
# Verificar espacio disponible
df -h

# La base de datos ocupa ~200MB comprimida, ~500MB descomprimida
```

## 📚 Referencias

- **OMIM Entry**: [Achondroplasia](https://www.omim.org/entry/100800)
- **NCBI Gene**: [FGFR3](https://www.ncbi.nlm.nih.gov/gene/2261)
- **BLAST Documentation**: [NCBI BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi)

## 👤 Autor

**Alexander Armua Abregu** (Legajo: 156.785-8)  
Sistemas Engineer Student - UTN Buenos Aires

## 📄 Licencia

Este proyecto es para fines académicos - Universidad Tecnológica Nacional

---

💡 **Tip**: Para análisis más profundos, considere usar herramientas como Clustal Omega para alineamiento múltiple de secuencias homólogas encontradas en BLAST.