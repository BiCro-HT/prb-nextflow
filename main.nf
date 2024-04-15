// for highly-repeated sequences alternative bath should be implemented

params.genome = "/path/to/your/genome.fa"
params.regions = "/path/to/your/all_regions.tsv"
params.nt = "nucleotide type (DNA or RNA)"
params.gcfilter = "GC filter (1 or 0)"
params.length = 40
params.sublength = ""
params.mismatch = 1
params.threads = 40
params.combsize = ""
params.countRepeat = 100
params.funcDB = "q_bl"
params.matchConsec = 24
params.maxConsecPolymer = 6
params.distance = 8
params.tempMelting = 72
params.greedy = "-greedy"

log.info """\
    F I S H   N E X T F L O W
    =========================
    Genome: ${params.genome}
    Regions: ${params.regions}
    Nucleotide type: ${params.nt}
    GC filter: ${params.gcfilter}
    Length: ${params.length}
    Sublength: ${params.sublength}
    Mismatch: ${params.mismatch}
    Threads: ${params.threads}
    Combsize: ${params.combsize}

""".stripIndent()

process MKDIRS {
    label "step 0: Create directories"

    script:
    """
    prb makedirs --genome ${params.genome} --regions ${params.regions}
    """

}

process GET_OLIGOS {
    label "step 1: Get oligos"

    script:
    """
    prb get_oligos ${params.nt} ${params.gcfilter}
    """
}

process NHUSH {
    label "step 3: NHUSH"

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
    label "step 4: Reform HUSH"

    script:
    """
    prb reform_hush_combined ${params.nt} ${params.length} ${params.sublength} ${params.mismatch}
    """
}

process MELT_SECS {
    label "step 5: Melt secondary structures"

    script:
    """
    prb melt_secs_parallel ${params.nt} 
    """
}

process GENERATE_BLACKLIST {
    label "step 6: Generate blacklist"

    script:
    """
    prb generate_blacklist -L ${params.length} -c ${params.countRepeat}
    """
}

process BUILD_DATABASE {
    label "step 7: Build database"

    script:
    """
    prb build-db_BL -f ${params.funcDB} -m ${params.matchConsec} -i ${params.maxConsecPolymer} -L ${length} -c ${countRepeat} -d ${params.distance} -T ${params.tempMelting} -y
    """
}

process QUERY {
    label "step 8: Cycling Query"

    script:
    """
    prb query_BL -s ${params.greedy} -L {params.length} -m {placeholder} -c ${params.countRepeat} -t ${params.threads}
    """
}