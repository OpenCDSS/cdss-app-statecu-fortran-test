# cdss-app-statecu-fortran-test

Colorado's Decision Support Systems (CDSS) StateCU consumptive use model.

This repository is envisioned to hold functional tests that will validate StateCU software features. 
For example, "small" tests may include:

1. reading model datasets without errors
2. running simple datasets to demonstrate core functionality
3. confirming that specific CU method work
4. running station and structure location datasets

Additionally, "large" tests may include:

1. running entire basin datasets to confirm that interaction of model features work as expected

Content will be added to this repository as existing testing approaches are adapted for the
OpenCDSS development environment.
It is challenging to implement tests due to the large size of model output for full datasets.
