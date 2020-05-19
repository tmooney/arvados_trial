#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "Downsample and HaplotypeCaller"
requirements:
    - class: ScatterFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: SubworkflowFeatureRequirement
inputs:
    reference:
        type: File
        secondaryFiles: [.fai, ^.dict]
        doc: "The reference that was used for the already-completed alignments"
    crams_to_downsample:
        type:
            type: array
            items:
                type: record
                name: crams
                fields:
                    cram:
                        type: File
                    downsample_ratio:
                        type: float
                        doc: 'the downsample ratio to use when reprocessing this CRAM'
    downsample_strategy:
        type:
            - "null"
            - type: enum
              symbols: ["HighAccuracy", "ConstantMemory", "Chained"]
    downsample_seed:
        type: int?
outputs:
    crams:
      type: File[]
      secondaryFiles: [.crai, ^.crai]
      outputSource: index_cram/indexed_cram
steps:
    downsample:
        run: ../tools/downsample.cwl
        scatter: [sam, probability]
        scatterMethod: dotproduct
        in:
            sam:
                source: crams_to_downsample
                valueFrom: $(self.cram)
            probability:
                source: crams_to_downsample
                valueFrom: $(self.downsample_ratio)
            reference: reference
            random_seed: downsample_seed
            strategy: downsample_strategy
        out: [downsampled_sam]
    bam_to_cram:
        run: ../tools/bam_to_cram.cwl
        scatter: bam
        in:
            reference: reference
            bam: downsample/downsampled_sam
        out: [cram]
    index_cram:
        run: ../tools/index_cram.cwl
        scatter: cram
        in:
            cram: bam_to_cram/cram
        out:
            [indexed_cram]
