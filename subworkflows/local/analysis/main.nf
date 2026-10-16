include { STAGE_ONE } from '../../../modules/local/stage_one/main'
include { STAGE_TWO } from '../../../modules/local/stage_two/main'
include { STAGE_THREE } from '../../../modules/local/stage_three/main'

workflow ANALYSIS {
    take:
    samples
    stage_one_script
    stage_two_script
    stage_three_script
    checksum_script

    main:
    STAGE_ONE(samples, stage_one_script, checksum_script)

    ch_stage_two_inputs = STAGE_ONE.out.results.map { meta, stage_one_output, sampleinfo ->
        tuple(meta, stage_one_output, sampleinfo)
    }
    STAGE_TWO(ch_stage_two_inputs, stage_two_script, checksum_script)

    ch_stage_three_inputs = STAGE_TWO.out.results.map { meta, stage_two_output, sampleinfo ->
        tuple(meta, stage_two_output, sampleinfo)
    }
    STAGE_THREE(ch_stage_three_inputs, stage_three_script, checksum_script)

    emit:
    results = STAGE_THREE.out.results
    checksums = STAGE_ONE.out.checksums.mix(STAGE_TWO.out.checksums).mix(STAGE_THREE.out.checksums)
    versions = STAGE_ONE.out.versions.mix(STAGE_TWO.out.versions).mix(STAGE_THREE.out.versions)
}