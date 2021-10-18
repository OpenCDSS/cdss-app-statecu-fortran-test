# test-results-doc

This document summarizes dataset test results for different software versions.
This summary can be updated as the software moves forward.
The comparisons that are listed have the most recent version at the top of this document.

* [Approach](#approach)
* [14.0.0-gfortran-win-64bit Compared to 13.10-gfortran-win-32bit](#1400-gfortran-win-64bit-compared-to-1310-gfortran-win-32bit)

----------------

## Approach

The approach for testing is generally to compare the current baseline version (the accepted version) with another version,
for example the next version that will be released.
In some cases, the baseline is compared with an old version, such as comparing 14.0.0 with 13.10, in order to establish a documented history.

The testing framework was used to run each of the CDSS datasets and compare results, as documented below.

It is expected that as a new version is released,
it will become the baseline to which newer versions are compared.

## `14.0.0-gfortran-win-64bit` Compared to `13.10-gfortran-win-32bit`

**These results have been updated to include 14.0.1 update to fix the bug where BD1 file was not being created for some datasets.  Only the datasets that had problems were re-run, with version noted in the comment.**

The `14.0.0-gfortran-win-64bit` (and `14.0.1-gfortran-win-64bit`) executable was compared to the `13.10-gfortran-win-32bit` executable to establish
that the version 14 executable produces the same results as the older and accepted version, or if different that the results are explainable.
This allows the version 14 executable to become the baseline.
Tolerances of 2, 10, 100, and 1000 were used to categorize differences.
If the "Number of Time Series Different" is zero,
It means that the absolute value of all differences was < 2.
The number of time series impacts the run time.

| **Dataset** | **Scenario** | **Total Time Series** | **Number of Time Series Different** | **Magnitude of Differences** | **Comments** | **Who** |
| -- | -- | -- | -- | -- | -- | -- |
| `cm2015_StateCU` | `cm2015` | 18864 | 173 | < 150 | | smalers |
| `cm2015_StateCU` | `cm2015B` | 18864 | 103 | < 90 | | smalers |
| `gm2015_StateCU` | `gm2015` | 13200 | 372 | < 221 | Used 14.0.1. `TOTAL` is largest. | smalers |
| `gm2015_StateCU` | `gm2015B` | 13200 | 150 | < 94 | Used 14.0.1. | smalers |
| `NP2018_StateCU_modified` | `NP2018` | 10080 | 0 | | | smalers |
| `NP2018_StateCU_modified` | `NP2018B` | 10080 | 0 | | | smalers |
| `RG2012_StateCU` | `rg2012` | 27158 | 1286 | < 1900 | `TOTAL` is largest | smalers |
| `RG2012_StateCU` | `rg2012_FactorSoUMeter`  | 27158 | 1191 | < 14720 | `DIST20.Sw Soil Content` is largest  | smalers |
| `RG2012_StateCU` | `rg2012_NoQ` | 27158 | 908 | < 1670 | | smalers |
| `RG2012_StateCU` | `rg2012_SoU` | 27158 | 1430 | < 13300 | `TOTAL SW Soil Content` is largest | smalers |
| `sj2015_StateCU` | `sj2015` | 7488 | 201 | < 70 | | smalers |
| `sj2015_StateCU` | `sj2015B` | 1560 | 51 | < 137 | Used 14.0.1.  **Note fewer locations than `sj2015` scenario.** | smalers |
| `SP2016_StateCU_modified` | `SP2016` | 13764 | 1759 | < 184 | Used 14.0.1. | smalers |
| `SP2016_StateCU_modified` | `SP2016_Restricted` | 13764  | 2080 | < 3078 | Used 14.0.1.  | smalers |
| `wm2015_StateCU` | `wm2015` | 6720 | 18 | < 3 | | smalers |
| `wm2015_StateCU` | `wm2015B` | 6720 | 0 | 0 | Used 14.0.1. No differences. | smalers |
| `ym2015_StateCU` | `ym2015` | 7344 | 35 | < 7 | | smalers |
| `ym2015_StateCU` | `ym2015B` | 1530 | 4 | < 3 | Used 14.0.1. **Note fewer locations than `ym2015` scenario.** | smalers |