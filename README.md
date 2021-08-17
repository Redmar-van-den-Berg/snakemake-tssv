[![Continuous Integration](https://github.com/Redmar-van-den-Berg/snakemake-tssv/actions/workflows/ci.yml/badge.svg)](https://github.com/Redmar-van-den-Berg/snakemake-tssv/actions/workflows/ci.yml)
[![PEP compatible](http://pepkit.github.io/img/PEP-compatible-green.svg)](http://pepkit.github.io)

# snakemake-tssv
Snakemake pipeline to run TSSV against on or more VCF files.

## Settings
Both the sample inputs and the configuration for the pipeline are set using
[PEP](http://pep.databio.org/en/2.0.0/). Please view this [example
configuration](https://github.com/Redmar-van-den-Berg/snakemake-tssv/blob/main/tests/pep/project_config_all_options.yml)
for all available options.

### PEP settings
The top level settings for the PEP configuration are listed below.

| Configuration     | Default value | Explanation |
| -------------     | ------------- | ----------- |
| pep_version       | 2.0.0         | Version of the pep standard to use. |
| sample_table      | **required**  | CSV file with sample information, the path to the CSV is relative to the project_config.yml file. See [here](https://github.com/Redmar-van-den-Berg/snakemake-tssv/blob/main/tests/pep/one-sample.csv) for an example. |
| snakemake-tssv    | **required**  | Subsection for pipeline specific settings, see below. |

### Pipeline specific settings
The pipeline specific settings should be placed under the
`snakemake-tssv` section, see this [example
configuration](https://github.com/Redmar-van-den-Berg/snakemake-tssv/blob/main/tests/pep/project_config_all_options.yml)
for details.
| snakemake-tssv    | Default value | Explanation |
| -------------     | ------------- | ----------- |
| vcf               | **required**  | A VCF file with variants to analyse using TSSV. |
| reference         | **required**  | The reference that was used to generated the VCF file. Is used to extract the flanking regions for the TSSV library. |
| flank_size        | 20            | The size of the flanking regions around the variants. |
| max_indel_size    | 20            | The maximum size of indels from the VCF file to include in the analysis. |
| output_folder     | false         | Enables the output folder for TSSV. **Should be used carefully, since it will output all fastq data, uncompressed.** |
| variants_per_file | 50            | How many variants should be analysed at once.  Lower values with distribute the analysis over more, smaller jobs. |


## Caveats and known issues
1. If `2*(--flank-size) + --max-size` is larger than the read size of your
   sequencing library, you will never find any hits. Also note that if this is
   only slightly smaller than your read size, very few reads will perfectly
   overlap the requested region, so you might still get very few results.

2. If you specify `output_folder: true`, all input fastq data will be written
   to disk, uncompressed. Only use this when you have sequenced a small
   library.
