# This Makefile contains helpful commands for downloading and analyzing data from the SRA.
# They can be run from the terminal by typing "make comand_name".  EX: Make BAM_stats
# Even if you never use these commands here, they provide a good example of ways to use the python
#  scripts included in this project.

# --- put test first, so `make` runs this and exits
test:
	python bin/test_requirements.py

#---------------Bio 496, Project ---------------

prot_and_dna: diamond_db bowtie2_index
	while read l; do \
	echo "Downloading $$l"; \
	fastq-dump --outdir Input/SRA_datasets/ --skip-technical --readids  --dumpbase --clip $$l; \
	echo "Scanning $$l with Bowtie 2..."; \
	bowtie2 -q -x Input/Genomes/all_genomes --no-unal Input/SRA_datasets/$$l.fastq  -S Input/SAM_files/$$l.sam; \
	echo "Scanning $$l with diamond..."; \
	diamond blastx -f 6  qseqid sseqid pident length mismatch qstart qend sstart send evalue bitscore sseq qseq -d Input/Proteins/all_diamond_db -q Input/SRA_datasets/$$l.fastq  -o Input/RAP_Results/$$l.m8; \
	echo "Scan Complete, Removing Data Sets"; \
	rm -f ~/ncbi/public/sra/*; \
	rm -f Input/SRA_datasets/*; \
	samtools view -bS Input/SAM_files/$$l.sam | samtools sort - Input/BAM_files/$$l; \
	samtools index Input/BAM_files/$$l.bam; \
	done <Input/SraAccList.txt; \

protein_hits_by_organism:
	python3 bin/hits_by_organism.py

setup:
	-mkdir Input Output Input/Proteins Input/RAP_Results Input/BAM_files Input/Genomes Input/SAM_files Input/SRA_datasets Input/xml_metadata
	echo "Setup complete. Errors may have been generated for folders that already exist. This is normal."

genome_download:
	while read acc; do \
	echo "Downloading: $$acc"; \
	(esearch -db nucleotide -query "$$acc")<Input/Genomes/GenomeAccList.txt | efetch -format fasta > Input/Genomes/$$acc.fasta; \
	done <Input/Genomes/GenomeAccList.txt; \

diamond_install:
	wget http://github.com/bbuchfink/diamond/releases/download/v0.9.19/diamond-linux64.tar.gz
	tar xzf diamond-linux64.tar.gz
	sudo cp diamond /usr/bin/

diamond_db:
	cat Input/Proteins/*.fasta > Input/Proteins/all.fna
	diamond makedb --in Input/Proteins/all.fna -d Input/Proteins/all_diamond_db

per_base_stats:
	python3 bin/bam_stats.py -i Input/BAM_files -o Output/

initial_diamond_scan: diamond_db
	while read l; do \
	echo "Downloading $$l"; \
	fastq-dump --outdir Input/SRA_datasets/ -N 100001 -X 200000 --skip-technical --readids  --dumpbase --clip $$l; \
	echo "Scanning $$l with diamond..."; \
	diamond blastx -f 6  qseqid sseqid pident length mismatch qstart qend sstart send evalue bitscore sseq qseq -d Input/Proteins/all_diamond_db -q Input/SRA_datasets/$$l.fastq  -o Input/RAP_Results/$$l.m8; \
	rm -f ~/ncbi/public/sra/$$l*; \
	rm -f Input/SRA_datasets/$$l.fastq; \
	done <Input/SraAccList.txt; \

diamond_scan: diamond_db
	while read l; do \
	echo "Downloading $$l"; \
	fastq-dump --outdir Input/SRA_datasets/ -N 100000 -X 1100000 --skip-technical --readids  --dumpbase --clip $$l; \
	echo "Scanning $$l with diamond..."; \
	diamond blastx -f 6  qseqid sseqid pident length mismatch qstart qend sstart send evalue bitscore sseq qseq -d Input/Proteins/all_diamond_db -q Input/SRA_datasets/$$l.fastq  -o Input/RAP_Results/$$l.m8; \
	rm -f ~/ncbi/public/sra/$$l*; \
	rm -f Input/SRA_datasets/$$l.fastq; \
	done <Input/SraAccList.txt; \

full_diamond_scan: diamond_db
	while read l; do \
	echo "Downloading $$l"; \
	fastq-dump --outdir Input/SRA_datasets/ --skip-technical --readids  --dumpbase --clip $$l; \
	echo "Scanning $$l with diamond..."; \
	diamond blastx -f 6  qseqid sseqid pident length mismatch qstart qend sstart send evalue bitscore sseq qseq -d Input/Proteins/all_diamond_db -q Input/SRA_datasets/$$l.fastq  -o Input/RAP_Results/$$l.m8; \
	rm -f ~/ncbi/public/sra/$$l*; \
	rm -f Input/SRA_datasets/$$l.fastq; \
	done <Input/SraAccList.txt; \

initial_scan: bowtie2_index
	while read l; do \
	echo "Downloading $$l"; \
	fastq-dump --outdir Input/SRA_datasets/ -N 100001 -X 200000 --skip-technical --readids  --dumpbase --clip $$l; \
	echo "Scanning $$l with Bowtie 2..."; \
	bowtie2 -q -x Input/Genomes/all_genomes --no-unal Input/SRA_datasets/$$l.fastq  -S Input/SAM_files/$$l.sam; \
	echo "Scan Complete, Removing Data Sets"; \
	rm -f ~/ncbi/public/sra/$$l*; \
	rm -f Input/SRA_datasets/$$l.fastq; \
	samtools view -bS Input/SAM_files/$$l.sam | samtools sort - Input/BAM_files/$$l; \
	samtools index Input/BAM_files/$$l.bam; \
	done <Input/SraAccList.txt; \
	echo "Processing SAM to BAM files and Indexing..."; \
	python3 bin/genome_coverage.py -r -i Input/BAM_files/ > Output/genome_coverage.tsv; \

full_scan: bowtie2_index
	while read l; do \
	echo "Downloading $$l"; \
	fastq-dump --outdir Input/SRA_datasets/ --skip-technical --readids  --dumpbase --clip $$l; \
	echo "Scanning $$l with Bowtie 2..."; \
	bowtie2 -q -x Input/Genomes/all_genomes --no-unal Input/SRA_datasets/$$l.fastq  -S Input/SAM_files/$$l.sam; \
	echo "Scan Complete, Removing Data Sets"; \
	rm -f ~/ncbi/public/sra/$$l*; \
	rm -f Input/SRA_datasets/$$l.fastq; \
	samtools view -bS Input/SAM_files/$$l.sam | samtools sort - Input/BAM_files/$$l; \
	samtools index Input/BAM_files/$$l.bam; \
	done <Input/SraAccList.txt; \
	echo "Processing SAM to BAM files and Indexing..."; \
	python3 bin/genome_coverage.py -r -i Input/BAM_files/ > Output/genome_coverage.tsv; \

sam_stats:
	python3 bin/sam_stats.py -i Input/BAM_files/ -o Output/

sam_hits:
	python3 bin/sam_hits.py -i Input/BAM_files/ -o Output/BAM_hits.csv

protein_stats:
	python3 bin/m8_stats.py -i Input/RAP_Results/ -o Output/

protein_hits:
	python3 bin/m8_hits.py -i Input/RAP_Results/ -o Output/protein_hits.csv



demo: clean
	#Download 100 sample reads
	fastq-dump --outdir Input/SRA_datasets/ -X 100000 --skip-technical --readids  --dumpbase --clip SRR3403834
	esearch -db nucleotide -query "NC_024711.1" | efetch -format fasta > Input/Genomes/NC_024711.1.fasta
	bowtie2-build Input/Genomes/NC_024711.1.fasta Input/Genomes/crassphage_index
	bowtie2 -q -x Input/Genomes/crassphage_index --no-unal  Input/SRA_datasets/SRR3403834.fastq  -S Input/SAM_files/demo_SRR3403834.sam
	#python bin/conserved_regions_csv.py -i Input/SAM_files/demo_SRR3403834.sra -o Output/demo_SRR3403834.csv -f
	#printf "Demo complete.\n100 Reads from SRR3403834 were downloaded to Input/SRA_datasets\nA bowtie2 index of the bases \"ACGTACGT\" was build\nThe dataset was scanned for this section of DNA using Bowtie2.\nA CSV file of the file should be available in the Output folder\nTo delete these files run \"make clean\""

#---------------Applying Python Scripts to BAM files---------------

# Runs bam_stats.py for each BAM file in Output/BAM_files/ and outputs to Output/BAM_stats_output.csv
BAM_stats:
	for f in Input/BAM_files/*.bam; do \
	python3 bin/bam_stats.py -i $$f -o Output/BAM_stats_output.csv -l 50; \
	done

# Turn your CSV files into heatmaps! Open this python file (bin/csv_to_heatmap.py) and
#  edit lines 64-70 to change what the heatmap looks like.
# Here is a good starting place for the Seaborn Heatmap: http://seaborn.pydata.org/generated/seaborn.heatmap.html
coverage_depth_heatmap: coverage_depth_csv
	python3 bin/csv_to_heatmap.py -i Output/coverage_depth.csv -o "Output/coverage_heatmap_$(date +"%d%b%H%M")"

conserved_regions_heatmap: conserved_regions_csv
	python3 bin/csv_to_heatmap.py -i Output/conserved_regions.csv -o "Output/conservation_heatmap_$(date +"%d%b%H%M")"

# Makes a coverage depth CSV from BAM files for visualization
coverage_depth_csv:
	python3 bin/coverage_depth_csv.py --number-splits 500 -i Input/BAM_files/ -o Output/coverage_depth.csv

# Makes a CSV file containing the conservation of each base
conserved_regions_csv:
	python3 bin/conservation_csv.py --number-splits 500 -i Input/BAM_files/ -o Output/conserved_regions.csv


#---------------Downloading SRA datasets and Generating BAM files---------------

#Makes split BAM files in the OUTPUT folder from BAM files in INPUT folder
split_BAM_files:
	mkdir Input/split_BAM_files/
	for file in Input/BAM_files/*.bam; do \
	echo "Splitting $$file, and writing to Output/split_BAM_files ..."; \
	file=$$(echo "$$file" | rev | cut -d"/" -f1 | rev); \
	file=$$(echo "$$file" | cut -d"." -f1); \
	python bin/split_bam.py -i Input/BAM_files/$$file.bam -o Output/split_BAM_files/ -l 50; \
	done
	echo "Indexing BAM files in Output/split_BAM_files..." ; \
	for file in Output/split_BAM_files/*.bam; do \
	samtools index $$file; \
	done

only_split_BAM_files:
	for file in Input/raw_BAM_files/*.bam; do \
	echo "Splitting $$file, and writing to Output/split_BAM_files ..."; \
	file=$$(echo "$$file" | rev | cut -d"/" -f1 | rev); \
	file=$$(echo "$$file" | cut -d"." -f1); \
	python bin/split_bam.py -i Input/raw_BAM_files/$$file.bam -o Output/split_BAM_files/ -l 50; \
	done
	echo "Indexing BAM files in Output/split_BAM_files..."; \
	for file in Output/split_BAM_files/*.bam; do \
	samtools index $$file; \
	done

# Converts SAM files to BAM files and splits by organism, sorts and indexes them one at a time.
raw_BAM_files: SAM_files
	for file in Input/SAM_files/*.sam; do \
	echo "Converting, sorting and indexing $$file..."; \
	file=$$(echo "$$file" | rev | cut -d"/" -f1 | rev); \
	file=$$(echo "$$file" | cut -d"." -f1); \
	samtools view -bS Input/SAM_files/$$file.sam | samtools sort - Input/raw_BAM_files/$$file; \
	samtools index Input/raw_BAM_files/$$file.bam; \
	done

only_raw_BAM_files:
	for file in Input/SAM_files/*.sam; do \
	echo "Converting, sorting and indexing $$file..."; \
	file=$$(echo "$$file" | rev | cut -d"/" -f1 | rev); \
	file=$$(echo "$$file" | cut -d"." -f1); \
	samtools view -bS Input/SAM_files/$$file.sam | samtools sort - Input/raw_BAM_files/$$file; \
	samtools index Input/raw_BAM_files/$$file.bam; \
	done

# Scans all of the files in the SRA_datasets folder with Bowtie 2 and outputs the results to SAM files in the SAM_Files folder
SAM_files: bowtie2_index small_sra_download
	for file in Input/SRA_datasets/*.fastq; do \
	echo "Scanning $$file with Bowtie 2..."; \
	file=$$(echo "$$file" | rev | cut -d"/" -f1 | rev); \
	file=$$(echo "$$file" | cut -d"." -f1); \
	bowtie2 -q -x Input/Genomes/all_genomes --no-unal  Input/SRA_datasets/$$file.fastq  -S Input/SAM_files/$$file.sam; \
	done

only_SAM_files:
	for file in Input/SRA_datasets/*.fastq; do \
	echo "Scanning $$file with Bowtie 2..."; \
	file=$$(echo "$$file" | rev | cut -d"/" -f1 | rev); \
	file=$$(echo "$$file" | cut -d"." -f1); \
	bowtie2 -q -x Input/Genomes/all_genomes --no-unal  Input/SRA_datasets/$$file.fastq  -S Input/SAM_files/$$file.sam; \
	done

# Constructs a single bowtie 2 index from everything in the Input/Genomes/ folder
bowtie2_index:
	-rm Input/Genomes/all_genomes.*
	cat Input/Genomes/*.fasta > Input/Genomes/all_genomes.fna
	bowtie2-build Input/Genomes/all_genomes.fna Input/Genomes/all_genomes

# Constructs a protein index using prerapsearch
protein_index:
	rm -f Input/Proteins/all.fna
	rm -f Input/Proteins/all.fasta
	cat Input/Proteins/*.fasta > Input/Proteins/all.fna
	prerapsearch -d Input/Proteins/all.fna -n Input/Proteins/all_proteins


# Downloads 100k reads from every run in SraAccList.txt (By default it will download reads 100,000 to 200,000 - 
#  if there are less than 100,000 reads it will download nothing)
small_sra_download:
	while read l; do \
	echo "Downloading $$l"; \
	fastq-dump --outdir Input/SRA_datasets/ -N 100001 -X 200000 --skip-technical --readids  --dumpbase --clip $$l; \
	done <Input/SraAccList.txt

# Downloads the FULL (BIG FILE SIZE) runs in Input/SraAccList.txt to Input/Metagenomes (.fastQ format not .sra).
# Please don't do this unless you know what you are doing.
full_sra_download:
	while read l; do \
	echo "Downloading $$l"; \
	fastq-dump --outdir Input/SRA_datasets/ --skip-technical --readids --split-files --dumpbase --clip $$l; \
	#This next line will delete the .sra file from ~/ncbi/public/sra; \
	-rm ~/ncbi/public/sra/$$l.sra; \
	done <Input/SraAccList.txt

# Deletes everything in the Input and Output folders
clean:
	-rm -r Input Output
	mkdir Input Output Output/split_BAM_files Input/raw_BAM_files Input/Genomes Input/SAM_files Input/SRA_datasets Input/xml_metadata

# Removes everything except SRA datasets and Genomes.
soft_clean:
	-rm Output/* Output/split_BAM_files/* Input/SAM_files/* Input/raw_BAM_files/*





