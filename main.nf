// for highly-repeated sequences alternative bath should be implemented

// Nextflow script for the FISH pipeline
params.get_genome = "get_T2T" // get_GRC or get_T2T
params.genome = "data/genome.fa" // path to the reference genome file
params.rois = "data/rois/all_regions.tsv" // path to the regions of interest file
params.nt = "DNA" // DNA or RNA
params.gcfilter = 1 // 0 for no filter, 1 for filter
params.length = 40 // length of the oligos MUST be the same with the "data/rois/all_regions.tsv"
params.sublength = 21 // length of the sub oligos 
params.mismatch = 2 // number of mismatches
params.threads = 40 // number of threads
params.combsize = 14
params.countRepeat = 100 //min abundance to be included in oligo blacklist
params.funcDB = "q_bl" //only for BUILD_DATABASE process 
params.matchConsec = 24 //
params.maxConsecPolymer = 6
params.distance = 8
params.cyc_mm = 8 // mismatch for CYC_QUERY process
params.tempMelting = 72
params.greedy = "-greedy" // only for CYC_QUERY process 
params.gap = 500 // only for CYC_QUERY process 
params.stepdown = 25 // only for CYC_QUERY process 
params.gappercent = null // only for CYC_QUERY process
params.cutoff = 1e6 // only for CYC_QUERY process



log.info """\
    F I S H   N E X T F L O W
    =========================
    Get genome: ${params.get_genome}
    Genome: ${params.genome}
    Regions of interest: ${params.rois}
    Nucleotide type: ${params.nt}
    GC filter: ${params.gcfilter}
    Length: ${params.length}
    Sublength: ${params.sublength}
    Mismatch: ${params.mismatch}
    Threads: ${params.threads}
    Combsize: ${params.combsize}
    Count repeat: ${params.countRepeat}
    Function DB: ${params.funcDB}
    Match consecutive: ${params.matchConsec}
    Max consecutive polymer: ${params.maxConsecPolymer}
    Distance: ${params.distance}
    Temperature melting: ${params.tempMelting}
    Greedy: ${params.greedy}
    Gap: ${params.gap}
    Stepdown: ${params.stepdown}
    Gap percent: ${params.gappercent}

""".stripIndent()

process MKDIRS {
    label "A1_Create_directories"


    output:
    val true

    script:
    """
    mkdir -p ${PWD}/data/rois
    mkdir -p ${PWD}/data/ref
    """

}

process MV_ROIS {
    label "B1_1_Move_ROIs"

    //publishDir "${workflow.projectDir}", mode: 'copy'

    input:
    val ready

    output:
    val true

    script:
    """
    cd ${PWD}
    cp ${baseDir}/tests/main/all_regions.tsv data/rois/all_regions.tsv
    """
}

process GET_REFERENCE {
    label "C2_Get_reference"
    //TODO! add the reference genome to the command

    input:
    val ready

    output:
    val true

   
    script:
    """
    cd ${PWD}
    
    # prb get_GRC -split -r latest

    """
}

process GET_OLIGOS {
    label "D3_Get_oligos"

    input:
    val ready

    output:
    val true

   

    script:
    """
    cd ${PWD}
    prb get_oligos ${params.nt} ${params.gcfilter}
    """
}

process NHUSH {
    label "E4_NHUSH"


    input:
    val ready

    output:
    val true

   

    script:
    """
    cd ${PWD}
    if [ -n "${params.sublength}" ]; then
        prb run_nHUSH -d ${params.nt} -L ${params.length} -l ${params.sublength} -m ${params.mismatch} -t ${params.threads} -i ${params.combsize} -y
    else
        prb run_nHUSH -d ${params.nt} -L ${params.length} -m ${params.mismatch} -t ${params.threads} -i ${params.combsize} -y
    fi
    """
}

process REFORM_HUSH {
    label "F5_Reform_HUSH"

    input:
    val ready

    output:
    val true

   

    script:
    """
    cd ${PWD}
    prb reform_hush_combined ${params.nt} ${params.length} ${params.sublength} ${params.mismatch}
    """
}

process MELT_SECS {
    label "G6_melt_secondary_structures"

    input:
    val ready

    output:
    val true

   

    script:
    """
    cd ${PWD}
    prb melt_secs_parallel ${params.nt} 
    """
}

process GENERATE_BLACKLIST {
    label "H7_Generate_blacklist"

    input:
    val ready

    output:
    val true

   

    script:
    """
    cd ${PWD}
    prb generate_blacklist -L ${params.length} -c ${params.countRepeat}
    """
}

process BUILD_DATABASE {
    label "I8_Build_database"

    input:
    val ready

    output:
    val true

   

    script:
    """
    cd ${PWD}
    prb build-db_BL -f ${params.funcDB} -m ${params.matchConsec} -i ${params.maxConsecPolymer} -L ${params.length} -c ${params.countRepeat} -d ${params.distance} -T ${params.tempMelting} -y
    """
}

process CYC_QUERY {
    label "J9_Cycling_query"

    input:
    val ready

    output:
    val true

   

    script:
    """
    cd ${PWD}
    prb query_BL -s ${params.nt} -L ${params.length} -m ${params.cyc_mm} -c ${params.cutoff} -t ${params.threads} -g ${params.gap} ${params.greedy}
    """
}

process SUMMARY {
    label "H=K10_Summarize_probes_final"

    input:
    val ready

    output:
    val true

   

    script:
    """
    cd ${PWD}
    prb summarize_probes_final
    """
}

process SUMMARY_VISUAL {
    label "L11_Summarize_probes_visual"

    input:
    val ready

    output:
    val true

    script:
    """
    cd ${PWD}
    prb visual_report
    """
}

workflow  {
    MKDIRS()
    MV_ROIS(MKDIRS.out)
    GET_REFERENCE(MV_ROIS.out)
    GET_OLIGOS(GET_REFERENCE.out)
    NHUSH(GET_OLIGOS.out)
    REFORM_HUSH(NHUSH.out)
    MELT_SECS(REFORM_HUSH.out)
    GENERATE_BLACKLIST(MELT_SECS.out)
    BUILD_DATABASE(GENERATE_BLACKLIST.out)
    CYC_QUERY(BUILD_DATABASE.out)
    SUMMARY(CYC_QUERY.out)
    SUMMARY_VISUAL(SUMMARY.out)
}