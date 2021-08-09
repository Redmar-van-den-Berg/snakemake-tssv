Changelog
==========

<!--
Newest changes should be on top.

This document is user facing. Please word the changes in such a way
that users understand how the changes affect the new version.
-->

v0.0.1
---------------------------
+ Add final_report.csv with combined, per marker results for each sample.
+ Merge the tssv json output for each sample into a single report.
+ Parse the tssv output into json.
+ Use an uncompressed vcf file as input.
+ Define the vcf input in the project configuration, instead of per sample.
+ TSSV output folder is disabled by default. It can be enabled by setting
`output_folder: true` in the project configuration.
+ The number of variants per file can now be configured (default=50).
+ The maximum indel size to include can now be configured (default=20).
+ The flanking size around the variants can now be configured (default=20).
+ Add reference to the project configuration.
+ Add support for project configuration using
[PEP](http://pep.databio.org/en/latest/).
+ Add integration tests using pytest-workflow and github workflows.
