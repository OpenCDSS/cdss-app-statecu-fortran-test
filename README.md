# cdss-app-statecu-fortran-test

Colorado's Decision Support Systems (CDSS) StateCU consumptive use model software tests.
See the [OpenCDSS StateCU software web page](https://opencdss.state.co.us/opencdss/statecu/)
for more information.

* [Background](#background)
* [Test Results Documentation](test-results-doc/README.md) - separate file with summary of test results
* [Repository Contents](#repository-contents)
* [Getting Started](#getting-started)
  1. [Set up StateCU Development Environment](#set-up-statecu-development-environment)
  2. [Clone Repository](#clone-repository)
  3. [Install TSTool](#install-tstool)
  4. [`statecu-test.bash` Script](#statecu-testbash-script)
* [Overview of Test Process](#overview-of-test-process)
  1. [Download Files and Install Datasets and Executables](#download-files-and-install-datasets-and-executables)
  2. [Create New Test Dataset Variant](#create-new-test-dataset-variant)
  3. [Run StateCU to Generate Output](#run-statecu-to-generate-output)
  4. [Create a Comparison](#create-a-comparison)
  5. [Run a Comparison and Visualize Results](#run-a-comparison-and-visualize-results)
* [Future Enhancements](#future-enhancements)

-----------------

## Background

This repository contains tests that help to validate StateCU software features.
Test processing is automated as much as possible and additional automation will be implemented in the future.
Tests consistent of:

1. Full dataset comparisons:
	1. Used to compare different StateCU versions and ensure reasonable results for full datasets.
	2. Used to compare the current software with reference (accepted baseline) version.
2. Small tests:
	1. Currently not implemented for StateCU.
	See StateMod for examples of this approach.

The working files for this repository contain full StateCU datasets.
It is recognized that modelers will use separate copies of datasets to perform modeling work independent of software development.
The purpose of the testing repository is to support software development,
not dataset development, although these activities may overlap.
Consequently, the folder structure and processes described in this repository
are focused on software development, not model dataset development.
Version control for model datasets is expected to occur elsewhere,
such as repositories for each dataset.

## Repository Contents

The following explains repository contents.
Dynamic files such as model run output and model executables are not saved
in the repository, as controlled by the main `.gitignore` file and other `.gitignore` files.
Only controlling configuration, scripts, and folder framework are saved in the repository.

```
C:\Users\user\                              User files on Windows.
/C/Users/user/                              User files on Git Bash, MinGW.
  cdss-dev/                                 CDSS development work.
    StateCU/                                StateCU product software development files.
      git-repos/                            Repositories for StateCU.
============= above this line, recommended; below this line repo controls ===========
        cdss-app-statecu-fortran/           StateCU software files.
        cdss-app-statecu-fortran-doc-dev/   StateCU developer's documentation.
        cdss-app-statecu-fortran-doc-user/  StateCU user documentation.
        cdss-app-statecu-fortran-test/      StateCU tests (this repository).
```

Files in this repository are as follows, using the `cm2015` dataset as an example.

```
cdss-app-statecu-fortran-test/               StateCU tests (this repository).
  .gitattriutes                              Repository configuration.
  .gitignore                                 Repository ignored files list.
  README.md                                  This file.
  downloads/                                 Folder where datasets and executables are downloaded.
    *.tstool                                 TSTool command files to download and unzip to test folder.
    datasets/                                Downloaded dataset zip files from CDSS, etc.
      cm2015_StateCU.zip                     Are unzipped to matching 'test/datasets/*/0-dataset' folder.
    executables/                             Downloaded executable files from CDSS, OpenCDSS,
                                             copies from development folder, etc.
      statecu-14.0.0.gfortran-win-64bit.exe  Executable program, copied to
                                             'test/datasets/*/exes/*/StateCU' folder.
  scripts/                                   Scripts to help with testing.
    statecu-test.bash                        Main script used to manage and run tests.
  test/                                      Main folder for all tests.
    datasets/                                Folder for all dataset tests.
      cm2015_StateCU/                        For example, Upper Colorado dataset,
                                             using CDSS download file name.
        0-dataset/                           The unzipped dataset files from dataset download - DO NOT MODIFY.
                                             The contents of the folder are copied to other folders.
        comp/                                Folder for comparisons.
          comp~executable1~executable2/      TSTool command files and output to compare two
                                             dataset variants for model executables.
        exes/                                Folder containing dataset variants for executables.
          statecu-14.0.0.gfortran-win-64bit/ Copy of '0-dataset' files for an executable.
                                             The folder name matches the StateCU executable name without `.exe`.
            StateCU/                         StateCU dataset main folder.  The Software is run in this folder.
              cm2015.*                       Model dataset files, used as input for the simulation.
              cm2015.rcu                     Dataset "response file" with configuration information.
              cm2015.BD1                     Binary output file, contains time series that are compared.
          statecu-13.11.gfortran-win-32bit/  Another executable dataset copy.
            StateCU/
              see above
  test-results-doc/                          Test results documentation.
    README.md                                Manually-created summary of testing results.
  tstool-templates/                          TSTool command file templates.
                                             Files are copied modified on the fly for specific comparisons.
    compare-statecu-runs/                    Command files used to compare full dataset results.
    ts-diff/                                 Command and other files used to compare
                                             and visualize one time series.
```

## Getting Started

This section provides brief instructions for getting started with testing.

### Set up StateCU Development Environment

The StateCU tests are run in a MinGW environment that is the same as used for StateCU development
(and is the same envrionment that is used for StateMod development and testing).
Therefore, follow the documentation for
[setting up a StateCU development environment](https://opencdss.state.co.us/statecu/latest/doc-dev/dev-new/overview/).

Running tests does not require full development environment.
However, because the MinGW environment is packaged with the Fortran compiler,
installing MinGW is most of the effort.
The MinGW environment provides a Linux environment running on Windows.

Git software should also be installed in order to clone the test repository (next section).

### Clone Repository

It is assumed that the person using this repository has basic Git software understanding and skills
and has configured Git within the MinGW environment,
such as for StateCU and StateMod software development.

To use the test repository, create top-level folders as described in the [`Repository Contents`](#repository-contents) section.
In the `git-repos` folder, run the following in an MSys2 64-bit terminal:

```
git clone https://github.com/OpenCDSS/cdss-app-statecu-fortran-test.git
```

### Install TSTool

The TSTool software is used to perform dataset comparisons.
At least version 14.0.0 should be installed.
See the [OpenCDSS TSTool](https://opencdss.state.co.us/opencdss/tstool/) software web page.

### `statecu-test.bash` Script

The `scripts/statecu-test.bash` script is provided to help with test management.
It helps to enforce the standard folder naming conventions and
performs tasks for new test setup.
It is efficient to use a command line script because
StateCU development uses an MSys2 MinGW environment
to support Fortran development.

To run the script, `cd` to the repository's `scripts` folder and then run:

```
  ./statecu-test.bash
```

The script will present an interactive menu to execute testing tasks,
as described in the sections below.

## Overview of Test Process

The following sections describe the overall test process.
The following terminology is used throughout the repository,
listed in order that drills down into the testing process.

| **Term** | **Description** |
|-- | -- |
| test dataset | The dataset downloaded from CDSS or other source. To avoid confusion, all test dataset folders use the name from the zip file (e.g., `cm2015_StateCU` rather than `cm2015`). If the StateCU dataset packaging changes in the future, the name in the zip file will be used. |
| executable | The executable StateCU program name.  On Windows, executable files have an extension `.exe` and on Linux the extension is omitted.  Executable filenames for recent StateCU versions are verbose (e.g., `statecu-14.0.0-gfortran-win-64bit`) in order to uniquely identify the version and avoid confusion. The naming convention may change in the future, for example as 64-bit becomes the default and there is no need to maintain 32-bit executable. |
| executable version | The StateCU executable program version (e.g., `14.0.0`). | 
| executable variant | A variant of the StateCU executable within the same version, for example 32bit/64bit and optimization level (e.g., may include `o3` or `check` in the filename). | 
| test dataset variant | A copy of the test dataset that reflects an executable variant.  For example, the `0-dataset` folder is copied to the `cm2015_StateCU/exes/statecu-14.0.0-gfortran-win-64bit` folder to create a new test dataset variant. |
| dataset working files | The test dataset (and test dataset variant) `StateCU` folder contains input files and the results of running a simulation. These working files are the same that would be used by a modeler in their modeling environment. The `StateCU` folder may be at the top level of a test dataset zip file or in a sub-folder, depending on how the dataset is packaged in the distribution zip file. |
| dataset response file | StateCU datasets use a "respone file" (`*.rcu`) to provide controlling properties for the dataset and simulation. See "dataset scenario". |
| dataset scenario | A test dataset `StateCU` folder typically contains more than one scenario corresponding to multiple response file names.  For example, the `cm2015` scenario (`cm2015.rcu`) corresponds to historical data and the `cm2015B` scenario (`cm2015B.rcu`) corresponds to baseline conditions.  The scenarios are consistent with StateMod model scenarios that follow similar naming conventions. |
| comparison | The results from comparing two test dataset variants. The `comps` folder under a test dataset contains comparisons, using a folder name `datasetvariant~datasetvariant2` for comparison results (e.g., `cm2015_StateCU/comps/statecu-14.0.0-gfortran-win-64bit~statecu-3.10-gfortran-win-32bit`). |
| binary output file | StateCU writes time series output to a `*.BD1` file extension file, which contains time series input and output. These time series are the data of interest when comparing results. |
| time series comparison | The comparison of two dataset variants focuses on comparing the time series from the binary output files.  The TSTool software is used to compare matching time series from two dataset variants and differences are noted in the comparison output files. Comparisons are made using criteria such as tolerance in order to ignore noise such as roundoff. |
| output file comparison | It is also possible to compare output text files, such as StateCU report files.  This approach is not currently implemented in StateCU tests because time series comparison provides a more granular result. |

Although it may be ideal to perform as many comparisons as possible to confirm software performance and results,
the number of permutations requires time resources, which has a cost.
For example, consider the following files necessary to complete a single comparison of two dataset variants (two model executables)
and each datasets scenarios (`cm2015` and `cm2015B`), which yields 4 comparisons:

```
test/
  datasets/
    cm2015_StateCU/
      exes/
        statecu-14.0.0-gfortran-win-64bit/
          StateCU/
            cm2015.rcu -> cm2015.BD1
            cm2015B.rcu -> cm2015B.BD1
        statecu-13.10-gfortran-win-32bit/
          StateCU/
            cm2015.rcu -> cm2015.BD1
            cm2015B.rcu -> cm2015B.BD1
      comps/
        statecu-14.0.0-gfortran-win-64bit~statecu-13.10-gfortran-win-32bit/
          results/
            cm2015-ts-diff.*        (results of comparing cm2015.BD1 time series)
```

Although a number of permutations should always be run before a software release
as part of a release checklist,
it is likely that a software developer will
focus on a dataset of interest in day-to-day work,
for example a dataset that contains features relevant to current development,
such as specific operations within a basin, groundwater, consumptive use method, etc.

Comparing full published datasets and their scenarios provides check-off for major milestones,
such as migrating from 32-bit to 64-bit compiler,
and making sure there are no major bugs in software updates.

StateCU include options in the control file (`*.ccu`) that can be used to vary the analysis.
This testing framework does not currently try to exercise those options on full datasets.
Smaller tests can be created to verify specific software features.

The following sections describe the mechanics of performing testing.
Note that once the folder structure has been established,
test datasets can be deleted and recreated as appropriate,
and updated files can be copied into the folders as appropriate.
For example, during active software development,
a new executable can be copied into dataset variant folder's `StateCU` folder
rather than recreating the entire dataset unzip process.

### Download Files and Install Datasets and Executables

**Execute this step when new versions of datasets and executables are available.**

This repository contains the `downloads` folder and TSTool command files
to download StateCU datasets from standard CDSS web locations.
Download files are large, dynamic, and are "gitignored" from the repository.
Therefore, the files must be downloaded to use in testing.

New downloads should occur when a new dataset or model executable needs to be tested.
If working in the development environment, model executables can be copied from
the `cdss-app-statecu-main/src/main/fortran` folder to the `downloads/executables` folder.
Executables can also be copied from CDSS or OpenCDSS websites, or other location.

The TSTool command files download and install the dataset files into the
`test/datasets/*/0-dataset` folder, for example
`test/datasets/cm2015_StateCU/0-dataset`.
The dataset files are then available to copy into folders for an executable,
to run for testing.
The `0-dataset` files should not be modified.

### Create New Test Dataset Variant

**Execute this step when a new executable comparison is necessary.**

The previous step creates a `0-dataset` folder that is copied to create a test dataset.
A test dataset is referred to as a "variant" because it contains a
specific StateCU executable variant with properties:

* StateCU version (e.g., `14.0.0`)
* compiler (e.g., `gfortran` or `Lahey`)
* compiler options (e.g., `check` and `o3`)
* 32/64-bit

Run the `statecu-test.bash` script and use the `newvariant` command to
initialize each test dataset of interest, which includes a selected dataset.
The selected executable is copied to the dataset `StateCU` folder.
A separate folder is necessary for each variant to fully isolate the dataset from another executable.
This ensures that there is no mixing of test results.

### Run StateCU to Generate Output

**Execute this step when a new dataset or StateCU executable has been installed.**

The StateCU executable in the test dataset is run using one of the following methods:

1. Use the `statecu-test.bash` script's `runstatecu` command to select and run a dataset.
2. To run from the command line, change to the `StateCU` folder in a command line window.
Run the executable in the folder as per normal StateCU conventions.

### Create a Comparison

**Execute this step to create a new comparison, for example when new executable is available.**

The StateCU output from the previous step is used to compare the output
of one test dataset variant with another.
Use the `statecu-test.bash` script's `newcomp` command to create a new comparison.
This creates a folder in the dataset named `comp/variant1~variant2`
(e.g., `statecu-14.0.0-gfortran-win-64bit~statecu-13.10-gfortran-win-32bit`),
which contains a comparison of the two datasets.
Note that a tilde character (`~`) is used to separate the executable names.

TSTool command files are used to compare the binary output files,
which form the bulk of the results.

### Run a Comparison and Visualize Results

**Execute this step frequently to (re)create comparison and review results.
For example, this can be run during development to evaluate how changes in software are impacting simulations.**

Use the `statecu-test.bash` script's `runcomp` command to create a comparison.
Output text files can be used to review the frequency and magnitude of differences.

Use the `vheatmap` command to view the differences for a specific time series as a heatmap.
The TSTool graph allows interactively reviewing the date and magnitude of differences.

## Future Enhancements

Initial implementation of the testing framework has focused on implementing a structured process for testing
and establishing conventions for consistency.
Although the framework includes some automation,
the process does currently require some interactive tasks and review
using the `test-statecu.bash` script.
The existing testing framework features can be leverated to increase automation.
