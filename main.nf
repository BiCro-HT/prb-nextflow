// for highly-repeated sequences alternative bath should be implemented

// Nextflow script for the FISH pipeline
params.get_genome = "get_T2T" // get_GRC or get_T2T
params.genome = "data/genome.fa" // path to the reference genome file
params.rois = "data/rois/all_regions.tsv" // path to the regions of interest file
params.nt = "DNA" // DNA or RNA
params.gcfilter = 1 // 0 for no filter, 1 for filter
params.length = 40 // length of the oligos MUST be the same with the "data/rois/all_regions.tsv"
params.sublength = "" 
params.mismatch = 2 // number of mismatches
params.threads = 40 // number of threads
params.combsize = ""
params.countRepeat = 100 //min abundance to be included in oligo blacklist
params.funcDB = "q_bl" //only for BUILD_DATABASE process 
params.matchConsec = 24 //
params.maxConsecPolymer = 6
params.distance = 8
params.tempMelting = 72
params.greedy = "-greedy" // only for CYC_QUERY process 
params.gap = 500 // only for CYC_QUERY process 
params.stepdown = 25 // only for CYC_QUERY process 
params.gappercent = null // only for CYC_QUERY process

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
    label "step 1: Create directories"

    script:
    """
    prb makedirs
    """

}

process MV_ROIS {
    label "step 1A: Move regions of interest"

    script:
    """
    cp ${params.rois} data/rois/all_regions.tsv
    """
}

process GET_REFERENCE {
    label "step 2: Get reference"
    //TODO! add the reference genome to the command
    script:
    """
    prb get_reference ${params.genome}
    """
}

process GET_OLIGOS {
    label "step 3: Get oligos"

    script:
    """
    prb get_oligos ${params.nt} ${params.gcfilter}
    """
}

process NHUSH {
    label "step 4: NHUSH"

    script:
    """
    if [ -n "${params.sublength}" ]; then
        prb run_nhush -d ${params.nt} -L ${params.length} -l ${params.sublength} -m ${params.mismatch} -t ${params.threads} -i ${params.combsize} -y
    else
        prb run_nhush -d ${params.nt} -L ${params.length} -m ${params.mismatch} -t ${params.threads} -i ${params.combsize} -y
    fi
    """
}

process REFORM_HUSH {
    label "step 5: Reform HUSH"

    script:
    """
    prb reform_hush_combined ${params.nt} ${params.length} ${params.sublength} ${params.mismatch}
    """
}

process MELT_SECS {
    label "step 6: Melt secondary structures"

    script:
    """
    prb melt_secs_parallel ${params.nt} 
    """
}

process GENERATE_BLACKLIST {
    label "step 7: Generate blacklist"

    script:
    """
    prb generate_blacklist -L ${params.length} -c ${params.countRepeat}
    """
}

process BUILD_DATABASE {
    label "step 8: Build database"

    script:
    """
    prb build-db_BL -f ${params.funcDB} -m ${params.matchConsec} -i ${params.maxConsecPolymer} -L ${length} -c ${countRepeat} -d ${params.distance} -T ${params.tempMelting} -y
    """
}

process CYC_QUERY {
    label "step 9: Cycling Query"

    script:
    """
    prb query_BL -s ${params.nt} -L ${params.length} -m ${placeholder} -c ${params.cutoff} -t ${params.threads} -g ${params.gap} ${params.greedy}
    """
}

process SUMMARY {
    label "step 10: Summarize Probes"

    script:
    """
    prb summarize_probes_final
    """
}

process SUMMARY_VISUAL {
    label "step 10: Summarize Probes Visual"

    script:
    """
    prb visual_report
    """
}