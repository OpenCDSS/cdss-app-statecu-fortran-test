# datasets

This folder contains the datasets for each published CDSS dataset,
using the name in the packaged zip file.
For example, the `cm2015_StateCU.zip` file is saved in folder `cm2015_StateCU`.

Within each dataset are the following folders.

| **Folder** | **Description** |
| -- | -- |
| `0-dataset` | The files from the original dataset download file, extracted so that the `StateCU` folder is a child of the `0-dataset` folder.  These files **are not** modified, and are used as the original copy, for inspection. |
| `statecu-14.0.0.gfortran-win-64bit` | Additional folders match the executable name being tested.  The original `0-dataset` files are copied into the executable folder name.  A full run can then be made and the results compared. |
