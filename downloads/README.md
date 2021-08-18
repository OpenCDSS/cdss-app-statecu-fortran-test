# downloads

Downloads folder for model datasets and StateCU executables.

## StateCU Datasets

StateCU datasets are available on the
[CDSS website](https://cdss.colorado.gov/modeling-data/consumptive-use-statecu).
To determine the download URL, right click on link and use "Copy link address".
The URL will be similar to the following if a LaserFiche resource,
or may be the URL to the CO DWR FTP site.

```
https://dnrweblink.state.co.us/cwcb/0/doc/199986/Electronic.aspx?searchid=625e6e08-1aa8-4afc-a3a3-2541a4bb9a2f
```

Download command files have checks to make sure the download is OK before unzipping into the
`test/datasets/*/0-dataset` folder.
After downloading, the dataset is unzipped into a `test/*/0-dataset` folder to use as the primary copy.

## StateCU Executables

StateCU executables are available on the
[OpenCDSS website](https://opencdss.state.co.us/statecu/).
To determine the download URL, right click on link and use "Copy link address".
Download command files have checks to make sure the download is OK.

After downloading, an executable can be copied into a `test/dataset/*/executable-name/StateCU` folder
to use to run the dataset.
