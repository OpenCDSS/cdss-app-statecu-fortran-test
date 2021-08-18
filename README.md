# cdss-app-statecu-fortran-test

Colorado's Decision Support Systems (CDSS) StateCU consumptive use model automated tests.

* [Background](#background)
* [Repository Contents](#repository-contents)
* [`statecu-test.bash` Script](#statecu-test.bash-script)
* [Overview of Test Process](#overview-of-test-process)
	+ [1. Download Files](#1download-files)

-----------------

## Background

This repository holds automated tests that help to validate StateCU software features.
Tests consistent of:

1. Full dataset comparisons:
	1. Used to compare different StateCU versions and note differences.
	2. Used to compare the current software with reference (validated) version.
2. Small tests:
	1. Current not implemented for StateCU.
	See StateMod for an example of approach.

Note that this test repository will contain working files for full StateCU datasets.
It is recognized that modelers will use separate copies of datasets.
The purpose of the testing database is to support software development,
not dataset development.
These activities may overlap.
The point is that the folder structure and processes described in this repository
are focused on software development, not model dataset development.
Version control for model datasets is expected to occur elsewhere.

## Repository Contents

The following explains repository contents.
Dynamic files such as model run output and model executables are not saved
in the repository, as per the main `.gitignore` file or other `.gitignore` files.

```
C:\Users\user\                           User files on Windows.
/C/Users/user/                           User files on Git Bash, MinGW.
  cdss-dev/                              CDSS development work.
    StateCU/                             StateCU product.
      git-repos/                         Repositories for StateCU.
============= above this line, recommended; below this line repo controls ===========
        cdss-app-statecu-fortran/        StateCU software files.
        cdss-app-statecu-fortran-test/   StateCU tests (this repository).
```

Files in this repository are as follows, using the `cm2015` dataset as an example.

```
cdss-app-statecu-fortran-test/                     StateCU tests (this repository).
  .gitattriutes                                    Repository configuration.
  .gitignore                                       Repository ignored files list.
  README.md                                        This file.
  downloads/                                       Folder where datasets and executables are downloaded.
    datasets/                                      Downloaded dataset zip files from CDSS, etc.
      cm2015_StateCU.zip                           Are unzipped to matching 'test/datasets/*/cdss-dataset' folder.
    executables/                                   Downloaded executable files from OpenCDSS, etc.
      statecu-14.0.0.gfortran-win-64bit.exe        Executable program, copied to 'test/datasets/*/*/StateCU' folder.
  scripts/                                         Scripts to help with testing.
    statecu-test.bash                              Script to help with managing tests.
  test/                                            Main folder for all tests.
    datasets/                                      Folder for all datasets.
      cm2015_StateCU/                              For example, Upper Colorado dataset,
                                                   using CDSS download file name.
        0-dataset/                                 The dataset files from dataset download - DO NOT MODIFY.
        statecu-14.0.0.gfortran-win-64bit/         Copy of '0-dataset' files.
                                                   Folder name matches executable name.
                                                   The dataset is run in this folder.
        statecu-13.11.gfortran-win-32bit/          Another executable dataset copy.
          diff-statecu-14.0.0.gfortran-win-64bit/  TSTool command files and output to compare
                                                   this model run with another model run.
```

## `statecu-test.bash` Script

The `statecu-test.bash` script is provided to help with test management.
It helps to enforce the standard folder naming conventions and
performs tasks for new test setup.
It is efficient to use a command line script because
StateCU development uses a MSys2 MinGW environment,

Once a dataset test folder has been initialized, and the model run,
TSTool command files are used to compare the results.

## Overview of Test Process

The following sections describe the overall testing process.

### 1. Download Files

This repository contains the `downloads` folder and TSTool command files
to download StateCU datasets and model executables.
These files are large, dynamic, and are "gitignored" from the repository.
Therefore, the files must be downloaded to use in testing.

New downloads should occur when a new dataset or model executable needs to be tested.
If working in the development environment, model executables can be copied from
the `cdss-app-statecu-main/src/main/fortran` folder.

The TSTool command files download and install the files into the
`test/datasets/*/0-dataset` folder, for example
`test/datasets/cm2015_StateCU/0-dataset`.
The dataset files are then available to copy into folders for an executable,
to run for testing.

### 2. Create New Test Dataset

The previous step creates a `0-dataset` folder that is copied to create a test dataset.
The test dataset is referred to as a "variant" because it contains a
specific StateCU executable variant (version, compiler, compiler options, 32/64-bit, etc.).

Run the `statecu-test.bash` script and use the `newtest` command to
initialize each test dataset of interest, which includes a selected
dataset and executable (in `StateCU` folder).
A separate folder is necessary to fully isolate the dataset from another executable.
This ensures that there is no mistake in mixing test results.

### 3. Run StateCU to Generate Output

The StateCU executable in the test dataset is run using one of the following methods:

1. Change to the `StateCU` folder in a command line window.
Run the executable in the folder.
2. Use the `statecu-test.bash` script's `run` command to select and run a dataset.

### 4. Create a Comparison

The StateCU output from the previous step is used to compare the output
of one test dataset variant with another.

TSTool command files are provided to compare the binary output files,
which form the bulk of the results.

### 5. Streamlined Testing

The initial testing focus is on the above steps.
However, it is possible to streamline automated testing by
automating running multiple datasets, creating comparisons,
and summarizing test results.
These features will be implemented once the initial automated testing approach is implemented.
