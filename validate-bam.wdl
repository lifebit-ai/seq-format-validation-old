version 1.0
## Copyright Broad Institute, 2017
## 
## This WDL performs format validation on SAM/BAM files in a list
##
## Requirements/expectations :
## - One or more SAM or BAM files to validate
## - Explicit request of either SUMMARY or VERBOSE mode in inputs.json
##
## Outputs:
## - Set of .txt files containing the validation reports, one per input file
##
## Cromwell version support 
## - Successfully tested on v32
## - Does not work on versions < v23 due to output syntax
##
## Runtime parameters are optimized for Broad's Google Cloud Platform implementation. 
## For program versions, see docker containers. 
##
## LICENSING : 
## This script is released under the WDL source code license (BSD-3) (see LICENSE in 
## https://github.com/broadinstitute/wdl). Note however that the programs it calls may 
## be subject to different licenses. Users are responsible for checking that they are
## authorized to run all programs before running this script. Please see the docker 
## page at https://hub.docker.com/r/broadinstitute/genomes-in-the-cloud/ for detailed
## licensing information pertaining to the included programs.

# WORKFLOW DEFINITION
workflow ValidateBamsWf {
  input {
    #Array[File] bam_array = ["/Users/eva/git/fix/test/PRJNA608224_Australia_Infected.Wuhan_Hu_1.Spliced_Nanopreprocess_alignment_SARS-COV2_pass.minimap2.sorted.bam"]
    Array[File] bam_array = ["s3://lifebit-user-data-50778203-8300-4b61-8caf-0795a091ed3f/deploit/teams/5fc3e61799766d00247f4936/users/5ffc7039789f8601c0ced817/dataset/60c86d19a4146301a5229e04/uploaded.bam"]
    #Array[File] bam_array = ["/Users/eva/git/fix/test/test_test2.bam"]
    #Array[File] bam_array = ["s3://lifebit-user-data-f0d08d30-1ff5-4d53-9128-9140f5e050ec/deploit/teams/5fc3e61799766d00247f4936/users/60c77bf4ec129e01a5a37e74/dataset/60c86d19a4146301a5229e04/test_test2.bam"]
    String gatk_docker = "broadinstitute/gatk:latest"
    String gatk_path = "/gatk/gatk"
  }

  # Process the input files in parallel
  scatter (input_bam in bam_array) {

    # Get the basename, i.e. strip the filepath and the extension
    String bam_basename = basename(input_bam, ".bam")

    # Run the validation 
    call ValidateBAM {
      input:
        input_bam = input_bam,
        output_basename = bam_basename + ".validation",
        docker = gatk_docker,
        gatk_path = gatk_path
    }
  }

  # Outputs that will be retained when execution is complete
  output {
    Array[File] validation_reports = ValidateBAM.validation_report
  }
}

# TASK DEFINITIONS

# Validate a SAM or BAM using Picard ValidateSamFile
task ValidateBAM {
  input {
    # Command parameters
    File input_bam
    String output_basename
    String? validation_mode
    String gatk_path
  
    # Runtime parameters
    String docker
    Int machine_mem_gb = 4
    Int addtional_disk_space_gb = 50
  }
    
  Int disk_size = ceil(size(input_bam, "GB")) + addtional_disk_space_gb
  String output_name = "${output_basename}_${validation_mode}.txt"
 
  command {
    ${gatk_path} \
      ValidateSamFile \
      --IGNORE_WARNINGS true \
      --IGNORE MISSING_READ_GROUP \
      --INPUT ${input_bam} \
      --OUTPUT ${output_name} \
      --MODE ${default="SUMMARY" validation_mode}
  }
  runtime {
    docker: docker
    memory: machine_mem_gb + " GB"
    disks: "local-disk " + disk_size + " HDD"
  }
  output {
    File validation_report = "${output_name}"
  }
}
