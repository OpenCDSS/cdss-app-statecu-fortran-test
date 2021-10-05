# tstool-templates

This folder contains TSTool template command files and supporting files,
which are used to automate test processing and visualization.
These files are copied to a "comps" folder in a dataset when creating a new comparison.
They can be used as is to run a comparison because the TSTool command line has
properties to indicate the dataset, scenario, etc.

Any improvements made to these templates can be copied into the comparison.

| **Folder** | **Description** |
| -- | -- |
| `compare-statecu-runs/` | Contains command file to compare StateCU dataset variant run output. |
| `ts-diff/` | Contains command file visualize a difference between a time series that is in two datasets. |
