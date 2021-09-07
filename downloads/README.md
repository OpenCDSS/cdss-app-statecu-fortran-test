# downloads

Downloads folder for model datasets and StateCU executables.

## StateCU Datasets

StateCU datasets are available on the
[CDSS website](https://cdss.colorado.gov/modeling-data/consumptive-use-statecu).
To determine the download URL, right click on link and use "Copy link address".

The URL will be similar to the following if the dataset is available on the Division of Water Resources (DWR) FTP site.

```
https://dnrftp.state.co.us/CDSS/ModelFiles/StateCU/cm2015_StateCU.zip
```

The URL will be similar to the following if a LaserFiche resource,
Downloading from LaserFiche is typically much slower.

```
https://dnrweblink.state.co.us/cwcb/0/doc/199986/Electronic.aspx?searchid=625e6e08-1aa8-4afc-a3a3-2541a4bb9a2f
```

TSTool command files are available to automate downloading and unzipping datasets.
Download command files have checks to make sure the download is OK before unzipping into the
`test/datasets/*/0-dataset` folder.
The dataset is unzipped into a `test/*/0-dataset` folder to use as the primary copy.

New command files can be created when new datasets are released.

## StateCU Executables

StateCU executables are available on the
[OpenCDSS website](https://opencdss.state.co.us/statecu/).
To determine the download URL, right click on link and use "Copy link address".

TSTool command files are available to automate downloading and unzipping StateCU software.
Download zip files are saved to the `executable-zips` folder and are unzipped into the `executables` folder.
Download command files have checks to make sure the download is OK before unzipping.
If necessary, executables can be saved into the `executables` folder,
for example when testing a new executable created in the development environment.

After unzipping, an executable can be copied into a `test/dataset/*/executable-name/StateCU` folder
to use to run the dataset.

New command files can be created when new executables are released.
