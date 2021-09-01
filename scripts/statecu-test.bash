#!/bin/bash
#
# statecu-test - utility to help manage StateCU tests in the development environment
#
# The script provides features to:
# - initialize folders for tests
# - run StateCU
# - run TSTool

# Supporting functions, alphabetized...

# List the download datasets:
# - specify the first parameter as:
#     "numbered" to number and indent
#     "indented" to indent
#     "raw" no indent and no number
# - TODO smalers 2021-08-18 may allow specifying a pattern to match for executable names
listDownloadDatasets() {
  local format
  local fileCount

  format="raw"
  if [ $# -gt 0 ]; then
    format="${1}"
  fi
  logText ""
  logText "Downloaded datasets in:  ${downloadsDatasetsFolder}"
  'ls' -1 ${downloadsDatasetsFolder} | grep -v README.md | awk -v format=${format} '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       if ( format == "numbered" ) {
         # Print with line numbers and indent.
         printf("  %d - %s\n", line, $0)
       }
       else if ( format == "indented" ) {
         # Print with no line numbers and indent.
         printf("  %s\n", $0)
       }
       else {
         # Print with no line numbers and no indent.
         printf("%s\n", $0)
       }

     }'

  # Return the number of files:
  # - use the same filters as above
  # - mainly want to know if non-zero
  fileCount=$('ls' -1 ${downloadsDatasetsFolder} | grep -v README.md | wc -l)
  return ${fileCount}
}

# List downloads/executables folder contents with line numbers.
# The number can then be entered to select an executable.
# - specify the first parameter as:
#     "numbered" to number and indent
#     "indented" to indent
#     "raw" no indent and no number
# - TODO smalers 2021-08-18 may allow specifying a pattern to match for executable names
listDownloadExecutables() {
  local format
  local fileCount

  format="raw"
  if [ $# -gt 0 ]; then
    format="${1}"
  fi

  'ls' -1 ${downloadsExecutablesFolder} | grep -v README.md | awk -v format=${format} '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       if ( format == "numbered" ) {
         # Print with line numbers and indent.
         printf("  %d - %s\n", line, $0)
       }
       else if ( format == "indented" ) {
         # Print with no line numbers and indent.
         printf("  %s\n", $0)
       }
       else {
         # Print with no line numbers and no indent.
         printf("%s\n", $0)
       }

     }'

  # Return the number of files:
  # - use the same filters as above
  # - mainly want to know if non-zero
  fileCount=$('ls' -1 ${downloadsExecutablesFolder} | grep -v README.md | wc -l)
  return ${fileCount}
}

# List the test datasets:
# - for example the list will contain "cm2015_StateCU"
# - if the first parameter is a dataset, list it's contents
x2_listTestDatasets() {
  local dataset datasetFolder

  dataset=$1

  if [ -n "${dataset}" ]; then
    datasetFolder="${datasetsFolder}/${dataset}"
    if [ -d "${datasetFolder}" ]; then
      logWarning ""
      logWarning "The requested dataset folder does not exist:"
      logWarning "  ${datasetFolder}"
    else
      logText ""
      logText "Executables that are in the ${dataset} folder:"
      'ls' -1 ${datasetsFolder}
    fi
  else
    logText ""
    logText "Datasets that are in the testing framework:"
    'ls' -1 ${datasetsFolder}
  fi
}

# List the test datasets:
# - first argument is the optional dataset, can have wildcards
x_listTestDatasets() {
  local ds

  ds=${1}
  if [ -n "${ds}" ]; then 
    logText ""
    logText "Test datasets matching:  ${testDatasetsFolder}/${ds}"
    'ls' -1 ${testDatasetsFolder}/${ds} | grep -v README.md | awk '{printf("  %s\n", $0)}'
  else
    logText ""
    logText "Test datasets in:  ${testDatasetsFolder}"
    'ls' -1 ${testDatasetsFolder} | grep -v README.md | awk '{printf("  %s\n", $0)}'
  fi
}

# List test datasets with line numbers.
# The number can then be entered to select a dataset.
# - specify the first parameter as:
#     "numbered" to number and indent
#     "indented" to indent
#     "raw" no indent and no number
# - return the number of datasets
listTestDatasets() {
  local ds format searchFolder
  local fileCount

  format="raw"
  ds=""
  # Brute force parse since can be 0, 1, or 2 parameters.
  if [ $# -gt 0 ]; then
    if [ "${1}" = "raw" -o "${1}" = "numbered" -o "${1}" = "indented" ]; then
      format="${1}"
    else
      ds=${1}
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${2}"
    else
      if [ -z "${ds}" ]; then
        ds=${2}
      fi
    fi
  fi

  if [ -n "${ds}" ]; then
    # Search specific dataset given a pattern.
    searchFolder="${testDatasetsFolder}/${ds}/exes"
  else
    # Search the main dataset folder.
    searchFolder="${testDatasetsFolder}"
  fi

  logDebug "format=${format}"

  #'ls' -1 ${testDatasetsFolder}/${ds} | grep -v README.md | awk -v format=${format} '
  'ls' -1 ${searchFolder} | grep -v README.md | awk -v format=${format} '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       if ( format == "numbered" ) {
         # Print with line numbers and indent.
         printf("  %d - %s\n", line, $0)
       }
       else if ( format == "indented" ) {
         # Print with no line numbers and with indent.
         printf("  %s\n", $0)
       }
       else {
         # Print with no line numbers and no indent.
         printf("%s\n", $0)
       }
     }'

  # Return the number of files:
  # - use the same filters as above
  # - mainly want to know if non-zero
  # - make sure to NOT check the return status in calling code
  fileCount=$('ls' -1 ${searchFolder} | grep -v README.md | wc -l)
  return ${fileCount}
}

# This version uses 'find'.
# List test dataset variants with line numbers.
# The number can then be entered to select a dataset variant.
# - specify the first parameter as:
#     "numbered" to number and indent
#     "indented" to indent
#     "raw" no indent and no number
# - specify the second parameter as dataset name or glob regex
#   TODO smalers 2021-08-18 need to get this to work
# - this is a copy of he listTestDatasetVariants function but with 'comps' instead of 'exes'
listTestDatasetComps() {
  local ds format maxdepth mindepth searchFolders
  local filterCommand
  local fileCount

  format="raw"
  ds=""
  # Brute force parse since can be 0, 1, or 2 parameters.
  if [ $# -gt 0 ]; then
    if [ "${1}" = "raw" -o "${1}" = "numbered" -o "${1}" = "indented" ]; then
      format="${1}"
    else
      ds=${1}
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${2}"
    else
      if [ -z "${ds}" ]; then
        ds=${2}
      fi
    fi
  fi
  logDebug "format=${format}"
  logDebug "ds=${ds}"
  logDebug "testDatasetsFolder=${testDatasetsFolder}"

  if [ -n "${ds}" ]; then
    # Have a dataset:
    # - search matching dataset folder
    #searchFolders=$('ls' -1 ${testDatasetsFolder}/${ds}/exes | grep -v README.md | awk '{printf("  %s\n", $0)}')
    #mindepth=1
    #maxdepth=1
    # Using 'ls' does not work because it omits the full path needed by 'find', so filter after the find.
    searchFolders=${testDatasetsFolder}
    mindepth=3
    maxdepth=3
    filterCommand="grep /${ds}/"
  else
    # Listing all combinations of dataset and comparisons:
    # - used in main menu to list without being a part of any action such as remove
    # - specify depth to get to the files under 'comps'
    # - no additional filter after the find is needed since listing all datasets
    searchFolders=${testDatasetsFolder}
    mindepth=3
    maxdepth=3
    filterCommand="cat"
  fi

  # Can't use ls because too complicated to filter.
  #'ls' -1 ${testDatasetsFolder}/* | grep -v ':' | grep -v '0-dataset' | grep -v -e '^$' | awk '
  # Use find to only get subfolders:
  # - 'find' will show folders like the following regardless of the starting folder and depth, but number of lines will be different:
  #   /c/Users/sam/cdss-dev/StateCU/git-repos/cdss-app-statecu-fortran-test/test/datasets/cm2015_StateCU/exes/statecu-14.0.0-gfortran-win-64bit
  find ${searchFolders} -mindepth ${mindepth} -maxdepth ${maxdepth} -type d | grep 'comps' | ${filterCommand} | awk -v format=${format} '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       # Split the long path and only print the last parts.
       nparts = split($0, parts, "/")
       if ( format == "numbered" ) {
         # Print with line numbers and indent.
         printf("  %d - %s/%s/%s\n", line, parts[nparts-2], parts[nparts-1], parts[nparts])
       }
       else if ( format == "indented" ) {
         # Print with no line numbers and indent.
         printf("  %s/%s/%s\n", parts[nparts-2], parts[nparts-1], parts[nparts])
       }
       else {
         # Print with no line numbers and no indent.
         printf("%s/%s/%s\n", parts[nparts-2], parts[nparts-1], parts[nparts])
       }
     }'

  # Return the number of files:
  # - use the same filters as above
  # - mainly want to know if non-zero
  fileCount=$(find ${searchFolders} -mindepth ${mindepth} -maxdepth ${mindepth} -type d | grep 'comps' | ${filterCommand} | wc -l)
  return ${fileCount}
}

# List the time series in a comparison:
# - the time series are taken from the TSTool CompareTimeSeries summary output file
# - first or second parameter can be 'raw', 'numbered', or 'indented'
# - first or second parameter can be the summary difference file
# - return the number of time series
listTestDatasetCompTimeSeries () {
  local format summaryFile

  format="raw"
  summaryFile=""
  # Brute force parse since can be 0, 1, or 2 parameters.
  if [ $# -gt 0 ]; then
    if [ "${1}" = "raw" -o "${1}" = "numbered" -o "${1}" = "indented" ]; then
      format="${1}"
    else
      summaryFile=${1}
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${2}"
    else
      if [ -z "${ds}" ]; then
        summaryFile=${2}
      fi
    fi
  fi

  if [ ! -f "${summaryFile}" ]; then
    logWarning "Summary file does not exist:  ${summaryFile}"
    return 0
  fi

  # Filter by # since it shows up in comments and also the header line.
  # Include the TSID and description columns in output.
  cat ${summaryFile} | grep -v '#' | awk -F'|' -v format=${format} '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       if ( format == "numbered" ) {
         # Print with line numbers and indent.
         printf("  %d - %s - %s\n", line, $5, $4)
       }
       else if ( format == "indented" ) {
         # Print with no line numbers and with indent.
         printf("  %s - %s\n", $5, $4)
       }
       else {
         # Print with no line numbers and no indent.
         printf("%s - %s\n", $5, $4)
       }
     }'

  # Return the number of time series:
  # - use the same filters as above
  # - mainly want to know if non-zero
  # - make sure to NOT check the return status in calling code
  tsCount=$(cat ${summaryFile} | grep -v '#' | wc -l)
  return ${tsCount}
}

# List test dataset comparisons.
# The number can then be entered to select a comparison.
# - specify the first parameter as:
#     "numbered" to number and indent
#     "indented" to indent
#     "raw" no indent and no number
# - return the number of comparisons
x_listTestDatasetComps() {
  local ds format searchFolder
  local fileCount

  format="raw"
  ds=""
  # Brute force parse since can be 0, 1, or 2 parameters.
  if [ $# -gt 0 ]; then
    if [ "${1}" = "raw" -o "${1}" = "numbered" -o "${1}" = "indented" ]; then
      format="${1}"
    else
      ds=${1}
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${2}"
    else
      if [ -z "${ds}" ]; then
        ds=${2}
      fi
    fi
  fi

  if [ -n "${ds}" ]; then
    # Search specific dataset given a pattern.
    searchFolder="${testDatasetsFolder}/${ds}/comps"
  else
    # Search the main dataset folder.
    searchFolder="${testDatasetsFolder}/*/comps"
  fi

  logDebug "format=${format}"

  #'ls' -1 ${testDatasetsFolder}/${ds} | grep -v README.md | awk -v format=${format} '
  'ls' -1 ${searchFolder} | grep -v README.md | awk -v format=${format} '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       if ( format == "numbered" ) {
         # Print with line numbers and indent.
         printf("  %d - %s\n", line, $0)
       }
       else if ( format == "indented" ) {
         # Print with no line numbers and with indent.
         printf("  %s\n", $0)
       }
       else {
         # Print with no line numbers and no indent.
         printf("%s\n", $0)
       }
     }'

  # Return the number of files:
  # - use the same filters as above
  # - mainly want to know if non-zero
  # - make sure to NOT check the return status in calling code
  fileCount=$('ls' -1 ${searchFolder} | grep -v README.md | wc -l)
  return ${fileCount}
}

# List test dataset variants with line numbers.
# The number can then be entered to select a dataset variant.
# - specify the first parameter as:
#     "numbered" to number and indent
#     "indented" to indent
#     "raw" no indent and no number
# - specify the second parameter as dataset name or glob regex
#   TODO smalers 2021-08-18 need to get this to work
x_ls_listTestDatasetVariants() {
  local ds format maxdepth mindepth searchFolder
  local fileCount

  format="raw"
  ds=""
  # Brute force parse since can be 0, 1, or 2 parameters.
  if [ $# -gt 0 ]; then
    if [ "${1}" = "raw" -o "${1}" = "numbered" -o "${1}" = "indented" ]; then
      format="${1}"
    else
      ds=${1}
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${2}"
    else
      if [ -z "${ds}" ]; then
        ds=${2}
      fi
    fi
  fi
  logDebug "format=${format}"
  logDebug "testDatasetsFolder=${testDatasetsFolder}"

  # Change to the main datasets folder:
  # - the following check is to make sure code does not have an error
  if [ ! -d "${testDatasetsFolder}" ]; then
    logWarning ""
    logWarning "Test datasets folder does not exist: ${testDatasetsFolder}"
    logWarning "Check the script code."
  fi
  logDebug "Changing to:  ${testDatasetsFolder}"
  cd ${testDatasetsFolder}
  # The search folder below assumes that 'cd' has occurred, to avoid full path listing.
  if [ -n "${ds}" ]; then
    # Listing dataset variants for a specific dataset, used for actions on specific variant:
    # - no filter necessary
    #searchFolder="${testDatasetsFolder}/ds/exes"
    searchFolder="${ds}/exes"
    filterCommand="cat"
    lsopt="-1"
  else
    # Listing dataset variants for all datasets, used for general information:
    # - filter to only folders
    #searchFolder="${testDatasetsFolder}/*/exes"
    searchFolder="*/exes"
    filterCommand="grep '/'"
    lsopt="-1R"
  fi
  logDebug "Search folder: ${searchFolder}"

  'ls' ${lsopt} ${searchFolder} | grep '/'

  #'ls' -1 ${searchFolder} | grep -v ':' | grep -v '0-dataset' | grep -v -e '^$' | awk '
  # Output will be something like the following so only show lines with slash.
  #   cm2015_StateCU/exes/statecu-13.10-gfortran-win-32bit:
  #   ClimateCU
  #   Crops
  #   DiversionsCU
  #   DocsCU
  #   LocationCU
  #   StateCU
  #   
  #   cm2015_StateCU/exes/statecu-14.0.0-gfortran-win-64bit:
  #   ClimateCU
  #   Crops
  #   DiversionsCU
  #   DocsCU
  #   LocationCU
  #   StateCU
  'ls' ${lsopt} ${searchFolder} | ${filterCommand} | awk '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       if ( format == "numbered" ) {
         # Print with line numbers and indent.
         printf("  %d - %s\n", line, $0)
       }
       else if ( format == "indented" ) {
         # Print with no line numbers and indent.
         printf("  %s\n", $0 )
       }
       else {
         # Print with no line numbers and no indent.
         printf("%s\n", $0)
       }
     }'

  # Return the number of files:
  # - use the same filters as above
  # - mainly want to know if non-zero
  # - DO NOT check the return status in calling code
  fileCount=$('ls' ${lsopt} ${searchFolder} | ${filterCommand} | wc -l)
  return ${fileCount}
}

# This version uses 'find'.
# List test dataset variants with line numbers.
# The number can then be entered to select a dataset variant.
# - specify the first parameter as:
#     "numbered" to number and indent
#     "indented" to indent
#     "raw" no indent and no number
# - specify the second parameter as dataset name or glob regex
#   TODO smalers 2021-08-18 need to get this to work
listTestDatasetVariants() {
  local ds format maxdepth mindepth searchFolders
  local filterCommand
  local fileCount

  format="raw"
  ds=""
  # Brute force parse since can be 0, 1, or 2 parameters.
  if [ $# -gt 0 ]; then
    if [ "${1}" = "raw" -o "${1}" = "numbered" -o "${1}" = "indented" ]; then
      format="${1}"
    else
      ds=${1}
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${2}"
    else
      if [ -z "${ds}" ]; then
        ds=${2}
      fi
    fi
  fi
  logDebug "format=${format}"
  logDebug "testDatasetsFolder=${testDatasetsFolder}"

  if [ -n "${ds}" ]; then
    # Have a dataset:
    # - search matching dataset folder
    #searchFolders=$('ls' -1 ${testDatasetsFolder}/${ds}/exes | grep -v README.md | awk '{printf("  %s\n", $0)}')
    #mindepth=1
    #maxdepth=1
    # Using 'ls' does not work because it omits the full path needed by 'find', so filter after the find.
    searchFolders=${testDatasetsFolder}
    mindepth=3
    maxdepth=3
    filterCommand="grep /${ds}/"
  else
    # Listing all combinations of dataset and executables:
    # - used in main menu to list without being a part of any action such as remove
    # - specify depth to get to the files under 'exes'
    # - no additional filter after the find is needed since listing all datasets
    searchFolders=${testDatasetsFolder}
    mindepth=3
    maxdepth=3
    filterCommand="cat"
  fi

  # Can't use ls because too complicated to filter.
  #'ls' -1 ${testDatasetsFolder}/* | grep -v ':' | grep -v '0-dataset' | grep -v -e '^$' | awk '
  # Use find to only get subfolders:
  # - 'find' will show folders like the following regardless of the starting folder and depth, but number of lines will be different:
  #   /c/Users/sam/cdss-dev/StateCU/git-repos/cdss-app-statecu-fortran-test/test/datasets/cm2015_StateCU/exes/statecu-14.0.0-gfortran-win-64bit
  find ${searchFolders} -mindepth ${mindepth} -maxdepth ${maxdepth} -type d | grep 'exes' | ${filterCommand} | awk -v format=${format} '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       # Split the long path and only print the last parts.
       nparts = split($0, parts, "/")
       if ( format == "numbered" ) {
         # Print with line numbers and indent.
         printf("  %d - %s/%s/%s\n", line, parts[nparts-2], parts[nparts-1], parts[nparts])
       }
       else if ( format == "indented" ) {
         # Print with no line numbers and indent.
         printf("  %s/%s/%s\n", parts[nparts-2], parts[nparts-1], parts[nparts])
       }
       else {
         # Print with no line numbers and no indent.
         printf("%s/%s/%s\n", parts[nparts-2], parts[nparts-1], parts[nparts])
       }
     }'

  # Return the number of files:
  # - use the same filters as above
  # - mainly want to know if non-zero
  fileCount=$(find ${searchFolders} -mindepth ${mindepth} -maxdepth ${mindepth} -type d | grep 'exes' | ${filterCommand} | wc -l)
  return ${fileCount}
}

# List test dataset variant scenarios, with no leading path:
# - specify the first parameter as:
#     "numbered" to number and indent
#     "indented" to indent
#     "raw" no indent and no number
# - second parameter is the path to the StateCU folder
# - return the number of scenarios
# - this is used by TSTool when doing a comparison
listTestDatasetVariantScenarios() {
  local format searchFolder statecuFolder
  local fileCount

  format="raw"
  statecuFolder=""
  # Brute force parse since can be 0, 1, or 2 parameters.
  if [ $# -gt 0 ]; then
    if [ "${1}" = "raw" -o "${1}" = "numbered" -o "${1}" = "indented" ]; then
      format="${1}"
    else
      statecuFolder=${1}
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${2}"
    else
      if [ -z "${ds}" ]; then
        statecuFolder=${2}
      fi
    fi
  fi

  logDebug "format=${format}"

  #'ls' -1 ${testDatasetsFolder}/${ds} | grep -v README.md | awk -v format=${format} '
  'ls' -1 ${statecuFolder}/*.rcu | awk -v format=${format} -F/ '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       # Remove the file extension in the line.
       sub(".rcu","",$NF)
       if ( format == "numbered" ) {
         # Print with line numbers and indent.
         printf("  %d - %s\n", line, $NF)
       }
       else if ( format == "indented" ) {
         # Print with no line numbers and with indent.
         printf("  %s\n", $NF)
       }
       else {
         # Print with no line numbers and no indent.
         printf("%s\n", $NF)
       }
     }'

  # Return the number of files:
  # - use the same filters as above
  # - mainly want to know if non-zero
  # - make sure to NOT check the return status in calling code
  fileCount=$('ls' -1 ${statecuFolder}/*.rcu | wc -l)
  return ${fileCount}
}

# This version uses 'find' with the old folder structure - use the above simpler version with 'exes' folder.
# List test dataset variants with line numbers.
# The number can then be entered to select a dataset variant.
# - specify the first parameter as:
#     "numbered" to number and indent
#     "indented" to indent
#     "raw" no indent and no number
# - specify the second parameter as dataset name or glob regex
#   TODO smalers 2021-08-18 need to get this to work
x_find_old_listTestDatasetVariants() {
  local ds format maxdepth mindepth searchFolders
  local fileCount

  format="raw"
  ds=""
  # Brute force parse since can be 0, 1, or 2 parameters.
  if [ $# -gt 0 ]; then
    if [ "${1}" = "raw" -o "${1}" = "numbered" -o "${1}" = "indented" ]; then
      format="${1}"
    else
      ds=${1}
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${2}"
    else
      if [ -z "${ds}" ]; then
        ds=${2}
      fi
    fi
  fi
  logDebug "format=${format}"
  logDebug "testDatasetsFolder=${testDatasetsFolder}"

  searchFolders=${testDatasetsFolder}
  mindepth=2
  maxdepth=2
  if [ -n "${ds}" ]; then
    # Search matching dataset folder
    searchFolders=$('ls' -1 ${testDatasetsFolder}/${ds}/${exes} | grep -v README.md | awk '{printf("  %s\n", $0)}')
    mindepth=1
    maxdepth=1
  fi

  # Can't use ls because too complicated to filter.
  #'ls' -1 ${testDatasetsFolder}/* | grep -v ':' | grep -v '0-dataset' | grep -v -e '^$' | awk '
  # Use find to only get subfolders:
  # - will show folders like:
  #   /c/Users/sam/cdss-dev/StateCU/git-repos/cdss-app-statecu-fortran-test/test/datasets/cm2015_StateCU/statecu-14.0.0.gfortran-win-64bit
  # - ignore the 0-dataset folders because don't want to remove 
  find ${searchFolders} -mindepth ${mindepth} -maxdepth ${maxdepth} -type d | grep -v '0-dataset' | grep -v 'comp' | awk -v format=${format} '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       nparts = split($0, parts, "/")
       if ( format == "numbered" ) {
         # Print with line numbers and indent.
         printf("  %d - %s/%s\n", line, parts[nparts-1], parts[nparts])
       }
       else if ( format == "indented" ) {
         # Print with no line numbers and indent.
         printf("  %s/%s\n", parts[nparts-1], parts[nparts])
       }
       else {
         # Print with no line numbers and no indent.
         printf("%s/%s\n", parts[nparts-1], parts[nparts])
       }
     }'

  # Return the number of files:
  # - use the same filters as above
  # - mainly want to know if non-zero
  fileCount=$(find ${searchFolders} -mindepth ${mindepth} -maxdepth ${mindepth} -type d | grep -v '0-dataset' | grep -v 'comp' | wc -l)
  return ${fileCount}
}

# List test dataset variants - called from the menu.
# - first parameter is optional dataset
listTestDatasetVariantsFromMenu() {
  local ds ndatasets

  if [ -n "$1" ]; then
    ds=$1
  fi
  listTestDatasetVariants indented ${ds}
  ndatasets=$?
  if [ "${ndatasets}" -eq 0 ]; then
    logInfo ""
    logInfo "There are no test dataset variants.  Need to create a test dataset with executable variant."
    return 0
  fi

  return 0
}

# List TSTool installation folders sorted by version number, oldest first:
# - the newest is listed first
# - sorting modifies the version in the installer path to force the correct order
# - first parameter is the CDSS folder
# - versions older than 14 will probably be listed with invalid filename do to removal of zero-padded parts
# - version 14 is the first version to use non-zero-padded version and is required for this script,
#   ignore all other versions
listTstoolFolders() {
  local cdssFolder
  cdssFolder=${1}

  if [ ! -d "${cdssFolder}" ]; then
    # Probably should not have been called.  Output nothing.
    logDebug "CDSS folder does not exist: ${cdssFolder}"
    return 0
  fi

  find ${cdssFolder} -mindepth 1 -maxdepth 1 -type d -name 'TSTool*' | awk -v debug=${debug} '{
    # Pad the software version in the listing with zeros to allow
    # a correct numerical sort on the version parts.  Original listing is similar to:
    #  /c/CDSS/TSTool-10.21.00
    #  /c/CDSS/TSTool-12.03.00
    #  /c/CDSS/TSTool-12.05.00
    #  /c/CDSS/TSTool-12.06.00
    #  /c/CDSS/TSTool-13.00.00
    #  /c/CDSS/TSTool-13.00.00dev
    #  /c/CDSS/TSTool-13.01.00
    #  /c/CDSS/TSTool-13.01.01
    #  /c/CDSS/TSTool-13.02.00
    #  /c/CDSS/TSTool-13.02.00dev
    #  /c/CDSS/TSTool-13.03.00dev
    #  /c/CDSS/TSTool-13.04.00
    #  /c/CDSS/TSTool-13.04.00.dev2
    #  /c/CDSS/TSTool-14.0.0.dev1
    if ( debug == "true" ) {
      # Only do this when troubleshooting because it prints to the same stream as the output list.
      #printf("[DEBUG] First awk input: %s\n", $0 )
    }
    # Split the path name by dash.
    split($0,pathParts,"-")
    # Version is second part.
    version=pathParts[2]
    # Split the version into parts:
    nVersionParts=split(version,versionParts,".")
    # There can be 3 or 4 parts:
    # - pad each part to 3 digits
    if ( nVersionParts == 3 ) {
      # No fourth part:
      # - fake a fourth part to force sort before "dev1", etc.
      versionPadded=sprintf("%04d.%04d.%04d.zzz", versionParts[1], versionParts[2], versionParts[3] )
    }
    else {
      versionPadded=sprintf("%04d.%04d.%04d.%s", versionParts[1], versionParts[2], versionParts[3], versionParts[4] )
    }
    printf("%s-%s\n", pathParts[1], versionPadded)
  }' | sort -r | awk -v debug=${debug} '{
    # Process the version back to the original non-padded numbers.  Input is like:
    #  /c/CDSS/TSTool-0013.0002.0000
    if ( debug == "true" ) {
      #printf("Second awk input: %s\n", $0 )
    }
    # Split the path by dash.
    split($0,pathParts,"-")
    # Version is second part.
    version=pathParts[2]
    # Split the version into parts:
    # - version, for example: 0001.0013.0000
    nVersionParts=split(version,versionParts,".")
    # There should always be 4 parts.
    if ( versionParts[4] == "zzz" ) {
      # Remove the dummy fourth part.
      versionUnpadded=sprintf("%d.%d.%d", versionParts[1], versionParts[2], versionParts[3] )
    }
    else {
      # Keep the dummy fourth part.
      versionUnpadded=sprintf("%d.%d.%d.%s", versionParts[1], versionParts[2], versionParts[3], versionParts[4] )
    }
    printf("%s-%s\n", pathParts[1], versionUnpadded)
  }'
  return 0
}

# ========================================================================================
# Start the logging functions:
# - code is currently maintained with the 'nsdataws' script
# - messages are always logged to /dev/stderr
# - if global ${logFile} is set and not empty, also log to the file
# - log*() functions can be called with arguments to output decorated log message
# - log*() functions can be called as follows to log stdout and stderr stream:  2>&1 | logXXXX
# - log*() functions can be called safely in functions that print to stdout for variable assignment
# - the main limitation is calling log*() function with no arguments will hang waiting for input - DON'T DO IT
#
# configureEcho() - sets ${echo2} to use with special characters that can color text
# echoStderr() - echo function parameters to /dev/stderr
# logDebug() - if ${debug} = "true", log with [DEBUG] decoration
# logError() - log with [ERROR] decoration
# logFileStart() - start the log file (subsequent writes will append)
# logInfo() - log with [INFO] decoration
# logText() - log without decoration, useful when prompting for input and logging program output
# logWarning() - log with [WARNING] decoration
# ========================================================================================

# Initialize global variables:
# - parseCommandLine() should set "debug" variable to true with -d
# - logFile should be initialized early in startup to a valid filename if logfile is used
debug="false"
logFile=""

# Character control sequences for ${echo2}:
# okColor - status is good
# warnColor - user needs to do something
# errorColor - serious issue
# menuColor - menu highlight
# endColor - switch back to default color
okColor=''
warnColor=''
errorColor=''

menuColor=''
endColor=''

# Determine which echo to use, needs to support -e to output colored text:
# - normally built-in shell echo is OK, but on Debian Linux dash is used, and it does not support -e
# - sets the global 'echo2' variable that can be used in other code
# - sets global variables to colorize text for terminal output
#      okColor
#      warnColor
#      errorColor
#      menuColor
#      endColor
configureEcho() {
  local testEcho

  echo2='echo -e'
  testEcho=$(echo -e test)
  if [ "${testEcho}" = '-e test' ]; then
    # The -e option did not work as intended:
    # -using the normal /bin/echo should work
    # -printf is also an option
    echo2='/bin/echo -e'
    # The following does not seem to work.
    #echo2='printf'
  fi

  # Strings to change colors on output, to make it easier to indicate when actions are needed:
  # - Colors in Git Bash:  https://stackoverflow.com/questions/21243172/how-to-change-rgb-colors-in-git-bash-for-windows
  # - Useful info:  http://webhome.csc.uvic.ca/~sae/seng265/fall04/tips/s265s047-tips/bash-using-colors.html
  # - See colors:  https://en.wikipedia.org/wiki/ANSI_escape_code#Unix-like_systems
  # - Set the background to black to eensure that white background window will clearly show colors contrasting on black.
  # - Yellow "33" in Linux can show as brown, see:  https://unix.stackexchange.com/questions/192660/yellow-appears-as-brown-in-konsole
  # - Tried to use RGB but could not get it to work - for now live with "yellow" as it is
  okColor='\e[1;40;32m' # status is good, 40=background black, 32=green
  warnColor='\e[1;40;93m' # user needs to do something, 40=background black, 33=yellow, 93=bright yellow
  errorColor='\e[0;40;31m' # serious issue, 40=background black, 31=red
  menuColor='\e[1;40;36m' # menu highlight 40=background black, 36=light cyan
  endColor='\e[0m' # To switch back to default color
}

# Echo all function parameters to stderr:
# - this relies on ${echo2} being defined (see 'configureEcho()' function)
echoStderr() {
  # If necessary, quote the string to be printed.
  ${echo2} "$@" >&2
}

# Get the StateCU folder for a test dataset variant:
# - sometimes is at the top level, sometimes one down
# - first parameter is the full path to the test dataset variant folder
# - the folder is echoed to stdout and can be assigned to a variable
# - if an error, echo "" to stdout and return 1
# - if success, the folder is echoed to stdout and return 0
getTestDatasetVariantStatecuFolder() {
  local statecuFolder testVariantExesFolder testVariantParentOfExesFolder

  if [ $# -lt 1 ]; then
    logWarning "Can't determine test dataset StateCU folder."
    echo ""
    return 1
  fi

  testVariantFolder=$1
  if [ ! -d "${testVariantFolder}" ]; then
    logWarning "Test dataset variant folder does not exist:"
    logWarning "  ${testVariantFolder}"
    logWarning "Can't determine test dataset StateCU folder."
    echo ""
    return 1
  fi

  logDebug "Test dataset variant folder: ${testVariantFolder}"
  testVariantExesFolder=$(dirname ${testVariantFolder})
  testVariantParentOfExesFolder=$(dirname ${testVariantExesFolder})
  logDebug "Main dataset folder for test variant: ${testVariantParentOfExesFolder}"
  
  # Try case where StateCU folder exists in the top of the dataset folder.
  # - for example:  cm2015_StateCU/exes/statecu-14.0.0-gfortran-win-64bit
  statecuFolder="${testVariantFolder}/StateCU"
  if [ -d "${statecuFolder}" ]; then
    logInfo ""
    logInfo "StateCU folder is in top folder of dataset:"
    logInfo "  ${statecuFolder}"
    echo "${statecuFolder}"
    return 0
  else
    # Try the subfolder in the dataset:
    # - for example:  SP2016_StateCU_modified/exes/statecu-14.0.0-gfortran-win-64bit/SP2016_StateCU_modified/StateCU
    # - the subfolder name has typically matched the zip file name but this is not guaranteed
    # - could do a "find" but want to ensure some consistency
    statecuFolder="${testVariantFolder}/$(basename ${testVariantParentOfExesFolder})/StateCU"
    if [ -d "${statecuFolder}" ]; then
      logInfo ""
      logInfo "StateCU folder is in first sub-folder of dataset:"
      logInfo "  ${statecuFolder}"
      echo "${statecuFolder}"
      return 0
    else
      logWarning ""
      logWarning "Unable to determine StateCU folder in dataset:"
      logWarning "  ${testVariantFolder}"
      logWarning "Need to check script code to handle more dataset organization cases."
      echo ""
      return 1
    fi
  fi
  # Should not get her but if do return an error.
  echo ""
  return 1
}

# Log a debug message:
# - [DEBUG] is prefixed to arguments
# - prints to stderr and optionally appends to log file if ${logFile} is defined globally
# - if ${debug} is not set to "true", don't output
# - see logFileStart() to start a log file
# - call with parameters or pipe stdout and stderr to this function: 2>&1 | logDebug
logDebug() {
  local inputFile

  if [ ! "${debug}" = "true" ]; then
    # Debug is off so don't print debug message.
    return 0
  fi
  if [ "$#" -ne 0 ]; then
    # Content as provided as function parameter.
    if [ -n "${logFile}" ]; then
      # Are using a log file.
      echoStderr "[DEBUG] $@"
      ${echo2} "[DEBUG] $@" >> ${logFile}
    else
      # Are NOT using a log file.
      echoStderr "[DEBUG] $@"
    fi
  else
    # Output to stderr and the log file.
    if [ -n "${logFile}" ]; then
      cat | tee /dev/stderr >> ${logFile}
    else
      cat >&2
    fi
  fi
  return 0
}

# Log an error message:
# - [ERROR] is prefixed to arguments
# - prints to stderr and optionally appends to log file if ${logFile} is defined globally
# - see logFileStart() to start a log file
# - call with parameters or pipe stdout and stderr to this function: 2>&1 | logError
logError() {
  local inputFile

  if [ "$#" -ne 0 ]; then
    # Content as provided as function parameter.
    if [ -n "${logFile}" ]; then
      # Are using a log file.
      echoStderr "[ERROR] $@"
      ${echo2} "[ERROR] $@" >> ${logFile}
    else
      # Are NOT using a log file.
      echoStderr "[ERROR] $@"
    fi
  else
    # Output to stderr and the log file.
    if [ -n "${logFile}" ]; then
      cat | tee /dev/stderr >> ${logFile}
    else
      cat >&2
    fi
  fi
}

# Start a new logfile:
# - name of program that is being run is the first argument
# - path to the logfile is the second argument - if not specified use /dev/stderr
# - echo a line to the log file to (re)start
# - subsequent writes to the file using log*() functions will append
# - the global variable ${logFile} will be set for use by log*() functions
logFileStart() {
  local newLogFile now programBeingLogged
  programBeingLogged=$1
  # Set the global logfile, in case it was not saved.
  if [ -n "${2}" ]; then
    logFile=${2}
    now=$(date '+%Y-%m-%d %H:%M:%S')
    # Can't use logInfo because it only appends and want to restart the file.
    echoStderr "[INFO] Log file is: ${logFile}"
    echo "[INFO] Log file for ${programBeingLogged} started at ${now}" > ${logFile}
  else
    # logFile is checked in other functions to decide how to output.
    echoStderr "[INFO] Logging is to stderr."
  fi
}

# Log an information message:
# - [INFO] is prefixed to arguments
# - prints to stderr and optionally appends to log file if ${logFile} is defined globally
#   - see logFileStart() to start a log file
# - call with parameters or pipe stdout and stderr to this function: 2>&1 | logInfo
logInfo() {
  local inputFile

  if [ "$#" -ne 0 ]; then
    # Content as provided as function parameter.
    if [ -n "${logFile}" ]; then
      # Are using a log file.
      echoStderr "[INFO] $@"
      ${echo2} "[INFO] $@" >> ${logFile}
    else
      # Are NOT using a log file.
      echoStderr "[INFO] $@"
    fi
  else
    # Output to stderr and the log file.
    if [ -n "${logFile}" ]; then
      cat | tee /dev/stderr >> ${logFile}
    else
      # Just send to stderr.
      cat >&2
    fi
  fi
}

# Log a text message:
# - no prefix is added to arguments
# - prints to stderr and optionally appends to log file if ${logFile} is defined globally
# - see logFileStart() to start a log file
# - call with parameters or pipe stdout and stderr to this function: 2>&1 | logText
logText() {
  local inputLine

  if [ "$#" -ne 0 ]; then
    # Content was provided as function parameter.
    if [ -n "${logFile}" ]; then
      # Are using a log file.
      echoStderr "$@"
      ${echo2} "$@" >> ${logFile}
    else
      # Are NOT using a log file.
      echoStderr "$@"
    fi
  else
    # Output to stderr and the log file.
    if [ -n "${logFile}" ]; then
      cat | tee /dev/stderr >> ${logFile}
    else
      cat >&2
    fi
  fi
}

# Log a warning message:
# - [WARNING] is prefixed to arguments
# - prints to stderr and optionally appends to log file if ${logFile} is defined globally
# - see logFileStart() to start a log file
# - call with parameters or pipe stdout and stderr to this function: 2>&1 | logWarning
logWarning() {
  local inputFile

  if [ "$#" -ne 0 ]; then
    # Content as provided as function parameter.
    if [ -n "${logFile}" ]; then
      # Are using a log file.
      echoStderr "[WARNING] $@"
      ${echo2} "[WARNING] $@" >> ${logFile}
    else
      # Are NOT using a log file.
      echoStderr "[WARNING] $@"
    fi
  else
    # Output to stderr and the log file.
    if [ -n "${logFile}" ]; then
      # Are using a log file.
      cat | tee /dev/stderr >> ${logFile}
    else
      cat >&2
    fi
  fi
}

# ========================================================================================
# End the logging functions.
# ========================================================================================

# Create a new test dataset:
# - currently prints instructions for using TSTool
newTestDataset() {

  logText ""
  logText "Create a new test dataset."
  logText "Currently, this requires running TSTool separately to download and/or unzip a dataset file."
  logText "TSTool download command files are in the following folder:"
  logText "  ${downloadsFolder}"
  logText "which can be listed with the 'lsdds' menu command."
  logText "If the dataset has been previously downloaded and only unzip is needed,"
  logText "select and run the UnzipFile and necessary other commands in the TSTool command file."
  logText ""
  return 0
}

# Create a new test dataset comparison:
# - prompt for the dataset
# - prompt for the executable
newTestDatasetComp() {
  local selectedDataset selectedDataset1 selectedDataset2 selectedDatasetNumber
  local selectedExecutable selectedExecutableNumber
  local datasetExesFolder

  # Make sure that the program is not in a folder to be removed:
  # - just change to the initial ${scriptFolder}
  cd ${scriptFolder}

  logText ""
  logText "Create a new test dataset comparison (for two dataset variants)."
  logText "The following will occur set up the comparison."
  logText " - select two variants"
  logText " - create a 'dataset/comps/variant1~variant2' folder"
  logText " - the 'tstool-templates/*' files are copied to the 'comps' folder"
  logText " - TSTool is started with the appropriate command file to run the comparison"
  selectedDatasetVariant1=""
  selectedDatasetVariant2=""
  # Loop until have 2 selected dataset variants that are not the same.
  while [ "1" = "1" ]; do
    logText ""
    logText "Available dataset variants:"
    logText ""
    listTestDatasetVariants numbered
    ndatasets=$?
    if [ "${ndatasets}" -eq 0 ]; then
      logInfo ""
      logInfo "There are no dataset variants.  Need to create a test dataset variant in order to compare."
      return 0
    fi
    logText ""
    logText "Two dataset variants need to be selected for a comparison."
    logText "${menuColor}Select each number separately${endColor} by responding to two prompts."
    logText "Typically the baseline variant is selected first."
    read -p "Select a dataset variant (#/q/ ): " selectedDatasetNumber
    if [ "${selectedDatasetNumber}" = "q" -o "${selectedDatasetNumber}" = "Q" ]; then
      exit 0
    elif [ -z "${selectedDatasetNumber}" ]; then
      # Don't want to continue.
      return 0
    else
      # Selected a dataset variant - set in one of the two variables.
      selectedDatasetVariant=$(listTestDatasetVariants | head -${selectedDatasetNumber} | tail -1)
      if [ -z "${selectedDatasetVariant1}" ]; then
        selectedDatasetVariant1=${selectedDatasetVariant}
      elif [ -z "${selectedDatasetVariant2}" ]; then
        selectedDatasetVariant2=${selectedDatasetVariant}
      fi
      logText ""
      logText "Selected dataset variant (1): ${okColor}${selectedDatasetVariant1}${endColor}"
      logText "Selected dataset variant (2): ${okColor}${selectedDatasetVariant2}${endColor}"
      logText ""
      if [ -z "${selectedDatasetVariant1}" -o -z "${selectedDatasetVariant2}" ]; then
        # If one of the datasets is not selected, keep looping until 2 datasets are selected.
        continue
      elif [ "${selectedDatasetVariant1}" = "${selectedDatasetVariant2}" ]; then
        # Datasets are the same:
        # - unset one of the datasets so that it can be selected in the outer loop
        while [ "1" = "1" ]; do
          logWarning ""
          logWarning "${warnColor}Both dataset variant names are the same.${endColor}"
          read -p "Enter 1 or 2 to clear a selection (1/2/q/ ): " selectedDatasetNumber
          if [ "${selectedDatasetNumber}" = "q" -o "${selectedDatasetNumber}" = "Q" ]; then
            exit 0
          elif [ "${selectedDatasetNumber}" = "1" ]; then
            selectedDatasetVariant1=""
            logText ""
            logText "Selected dataset variant (1): ${okColor}${selectedDatasetVariant1}${endColor}"
            logText "Selected dataset variant (2): ${okColor}${selectedDatasetVariant2}${endColor}"
            logText ""
            # Outer loop will print available variants.
            break
          elif [ "${selectedDatasetNumber}" = "2" ]; then
            selectedDatasetVariant2=""
            logText ""
            logText "Selected dataset variant (1): ${okColor}${selectedDatasetVariant1}${endColor}"
            logText "Selected dataset variant (2): ${okColor}${selectedDatasetVariant2}${endColor}"
            logText ""
            # Outer loop will print available variants.
            break
          fi
        done
      fi
    fi
    if [ -n "${selectedDatasetVariant1}" -a -n "${selectedDatasetVariant2}" -a "${selectedDatasetVariant1}" != "${selectedDatasetVariant2}" ]; then
      # Have two datasets:
      # - check that the dataset is the same.
      # - main dataset is the first part of the selection, from a string like:
      #     cm2015_StateCU/exes/statecu-14.0.0-gfortran-win-64bit
      selectedDataset1=$(echo ${selectedDatasetVariant1} | cut -d '/' -f 1)
      selectedDataset2=$(echo ${selectedDatasetVariant2} | cut -d '/' -f 1)
      if [ "${selectedDataset1}" != "${selectedDataset2}" ]; then
        logWarning ""
        logWarning "${warnColor}The dataset is not the same for the two variants:${endColor}"
        logWarning "${warnColor}  ${selectedDataset1}"
        logWarning "${warnColor}  ${selectedDataset2}"
        logWarning "${warnColor}Select two dataset variants that have the same dataset.${endColor}"
        logWarning "${warnColor}Clearing the selections.${endColor}"
        selectedDatasetVariant1=""
        selectedDatasetVariant2=""
        continue
      else
        # Have input to create the comparison.
        break
      fi
    else
      # Need to continue selecting datasets.
      continue
    fi

    # Go to the top of the loop and continue selecting dataset variants.
  done

  # Confirm the selections.
  logText ""
  logText "The following dataset variants have been selected:"
  logText ""
  logText "Selected dataset variant (1): ${selectedDatasetVariant1}"
  logText "Selected dataset variant (2): ${selectedDatasetVariant2}"
  logText ""
  read -p "Continue creating dataset comparison (Y/n/q)? " answer
  # Define here since used in multiple places below.
  selectedDataset="${testDatasetsFolder}/${selectedDataset1}"
  compsFolder="${selectedDataset}/comps"
  selectedDatasetVariantName1=$(echo ${selectedDatasetVariant1} | awk -F/ '{print $NF}')
  selectedDatasetVariantName2=$(echo ${selectedDatasetVariant2} | awk -F/ '{print $NF}')
  compFolder="${compsFolder}/${selectedDatasetVariantName1}~${selectedDatasetVariantName2}"
  if [ "${answer}" = "q" -o "${answer}" = "Q" ]; then
    exit 0
  elif [ -z "${answer}" -o "${answer}" = "q" -o "${answer}" = "Q" ]; then
    # Create the 'comps' folder under the dataset if it does not exist.
    if [ ! -d "${compsFolder}" ]; then
      mkdir ${compsFolder}
      if [ $? -ne 0 ]; then
        logWarning ""
        logWarning "${warnColor}${endColor}Error creating dataset comparison folder:"
        logWarning "  ${warnColor}${compsFolder}${endColor}"
        logWarning "${warnColor}Check the script code.${endColor}"
        return 1
      fi
    fi
    # Create the specific comparison folder:
    if [ -d "${compFolder}" ]; then
      logInfo ""
      logInfo "Dataset comparison folder exists:"
      logInfo "  ${compFolder}:"
      read -p "Replace (Y/n/q)? " answer
      if [ "${answer}" = "q" -o "${answer}" = "Q" ]; then
        exit 0
      elif [ -z "${answer}" -o "${answer}" = "y" -o "${answer}" = "Y" ]; then
        while [ "1" = "1" ]; do
          logInfo ""
          logInfo "Removing existing dataset comparison folder:"
          logInfo "  ${compFolder}"
          rm -rf "${compFolder}"
          if [ -d "${compFolder}" ]; then
            logWarning "${warnColor}Unable to remove folder:  ${testVariantFolder}${endColor}"
            logWarning "${warnColor}File(s) may be open in software.  Check and retry.${endColor}"
            read -p "Retry (Y/n/q)? " answer
            if [ "${answer}" = "q" -o "${answer}" = "Q" ]; then
              exit 0
            elif [ "${answer}" = "y" -o "${answer}" = "Y" ]; then
              continue
            else
              # Don't want to continue.
              return 0
            fi
          else
            logInfo "Success removing existing dataset comparison folder:"
            logInfo "  ${compFolder}"
            break
          fi
        done
      fi
    fi
    if [ ! -d "${compFolder}" ]; then
      # If here the comparison folder did not exist or was deleted so create.
      logInfo ""
      logInfo "Creating dataset comparison folder:"
      logInfo "  ${compFolder}"
      mkdir ${compFolder}
      if [ $? -ne 0 ]; then
        logWarning ""
        logWarning "${warnColor}Error creating dataset variant comparison folder:${endColor}"
        logWarning "  ${warnColor}${compFolder}${endColor}"
        logWarning "${warnColor}Check the script code.${endColor}"
        return 1
      fi
    fi
    # Create a results folder for TSTool.
    resultsFolder="${compFolder}/results"
    mkdir ${resultsFolder}
    if [ $? -ne 0 ]; then
      logWarning ""
      logWarning "${warnColor}Error creating comparison results folder:${endColor}"
      logWarning "  ${warnColor}${resultsFolder}${endColor}"
      logWarning "${warnColor}Check the script code.${endColor}"
      return 1
    fi
    # Copy the TSTool template command file for running the comparison and visualizations:
    # - currently, the templates are not modified
    # - controlling properties are specified on the command line when running TSTool
    tstoolFiles=( "compare-statecu-runs/compare-statecu-runs.tstool" "ts-diff/ts-diff.tstool" "ts-diff/ts-diff.csv" "ts-diff/ts-diff.tsp" )
    for tstoolFile in "${tstoolFiles[@]}"; do
      tstoolFile="${tstoolTemplatesFolder}/${tstoolFile}"
      logInfo ""
      logInfo "Copying TSTool command file:"
      logInfo "  from: ${tstoolFile}"
      logInfo "    to: ${compFolder}"
      cp ${tstoolFile} ${compFolder}
      if [ $? -eq 0 ]; then
        logInfo "${okColor}  Success copying TSTool command file.${endColor}"
      else
        logWarning "${warnColor}  Failure copying TSTool command file - check script code.${endColor}"
        return 1
      fi
    done
  else
    # Don't continue creating comparison.
    return 0
  fi
  return 0
}

# Create a new test dataset variant:
# - prompt for the dataset
# - prompt for the executable
newTestDatasetVariant() {
  local selectedDataset selectedDatasetNumber
  local selectedExecutable selectedExecutableNumber
  local datasetExesFolder

  # Make sure that the program is not in a folder to be removed:
  # - just change to the initial ${scriptFolder}
  cd ${scriptFolder}

  logText ""
  logText "Create a new test dataset variant (for a dataset and executable):"
  logText " - select a dataset and executable"
  logText " - the '0-dataset' files from the unzipped dataset"
  logText "   are copied to a test folder with name matching the executable"
  logText " - the original executable in the StateCU folder will remain and is ignored"
  logText " - the executable is copied into the StateCU folder of the test dataset"
  logText " - the model can then be run - the executable name matching the variant will be used"
  while [ "1" = "1" ]; do
    logText ""
    logText "Available datasets:"
    logText ""
    listTestDatasets numbered
    ndatasets=$?
    if [ "${ndatasets}" -eq 0 ]; then
      logInfo ""
      logInfo "There are no datasets.  Need to create a test dataset."
      return 0
    fi
    logText ""
    read -p "Select a dataset (#/q/ ): " selectedDatasetNumber
    if [ "${selectedDatasetNumber}" = "q" -o "${selectedDatasetNumber}" = "Q" ]; then
      exit 0
    elif [ -z "${selectedDatasetNumber}" ]; then
      break
    else
      # Have a dataset.  Next pick the executable.
      selectedDataset=$(listTestDatasets | head -${selectedDatasetNumber} | tail -1)
      logText ""
      logText "Selected dataset: ${selectedDataset}"
      logText ""
      testDatasetFolder="${testDatasetsFolder}/${selectedDataset}"
      if [ ! -d "${testDatasetFolder}" ]; then
        # This should not happen.
        logWarning "The main test dataset folder does not exist:"
        logWarning "  ${testDatasetFolder}"
        logWarning "Run the downloads command file to install the original dataset."
        return 1
      fi
      while [ "1" = "1" ]; do
        logText "Existing test dataset variants for dataset '${selectedDataset}' (can overwrite):"
        logText ""
        listTestDatasetVariants indented ${selectedDataset}
        logText ""
        logText "Available executables:"
        logText ""
        listDownloadExecutables numbered
        nexe=$?
        if [ "${nexe}" -eq 0 ]; then
          logInfo ""
          logInfo "There are no executables.  Need to download an executable."
          return 0
        fi
        logText ""
        read -p "Select an executable number (#/q/ ): " selectedExecutableNumber
        if [ "${selectedExecutableNumber}" = "q" -o "${selectedExecutableNumber}" = "Q" ]; then
          exit 0
        elif [ -z "${selectedExecutableNumber}" ]; then
          # Just return rather than chaining a break in the outside loop.
          return 0
        else
          # Have an executable.  Continue with creating the test dataset.

          # Make sure the "exes" folder exists.
          datasetExesFolder="${testDatasetFolder}/exes"
          if [ ! -d "${datasetExesFolder}" ]; then
            logInfo "Creating folder for dataset executable variants:"
            logInfo "  ${datasetExesFolder}"
            mkdir ${datasetExesFolder}
            if [ $? -ne 0 ]; then
              logError "Error creating folder for dataset executable variants:"
              logInfo "  ${datasetExesFolder}"
              logError "Need to check the script code."
              return 1
            fi
          fi

          # Select an executable to copy.
          selectedExecutable=$(listDownloadExecutables | head -${selectedExecutableNumber} | tail -1)
          logText "Selected executable: ${selectedExecutable}"
          # TODO smalers 2021-08-17 need to make sure this works on Linux where extensions will not be used.
          selectedExecutableNoExt=${selectedExecutable%.*}
          testVariantFolder="${testDatasetFolder}/exes/${selectedExecutableNoExt}"
          if [ -d "${testVariantFolder}" ]; then
            logWarning ""
            logWarning "Dataset test exists:"
            logWarning "  ${testVariantFolder}:"
            read -p "Replace (Y/n/q)? " answer
            if [ "${answer}" = "q" -o "${answer}" = "Q" ]; then
              exit 0
            elif [ -z "${answer}" -o "${answer}" = "y" -o "${answer}" = "Y" ]; then
              logInfo "Removing: ${testVariantFolder}"
              rm -rf "${testVariantFolder}"
              if [ $? -ne 0 ]; then
                logWarning "${warnColor}Unable to remove folder:  ${testVariantFolder}${endColor}"
                logWarning "${warnColor}File(s) may be open in software.  Check and retry.${endColor}"
                return 1
              fi
            else
              # Anything else.  Don't continue.
              return 0
            fi
          fi
          # If here the variant folder has been deleted and need to copy the dataset files and executable.
          # Copy the dataset.
          datasetFromFolder="${testDatasetFolder}/0-dataset"
          logInfo ""
          logInfo "Copying dataset files (may be slow if a large dataset):"
          logInfo "  from: ${datasetFromFolder}"
          logInfo "    to: ${testVariantFolder}"
          cp -r ${datasetFromFolder} ${testVariantFolder}
          if [ $? -eq 0 ]; then
             logInfo "${okColor}Success copying dataset files.${endColor}"
          else
             logWarning "${warnColor}Error copying dataset - check script code.${endColor}"
             return 1
          fi
          # Copy the executable:
          # - first determine the StateCU folder
          # - may be in top level of the dataset or one down due to zip file contents
          # - OK if another executable exists because the specific executable is run by this script
          statecuFolder=$(getTestDatasetVariantStatecuFolder ${testVariantFolder})
          if [ $? -ne 0 -o -z "${statecuFolder}" ]; then
            # Warnings will have been printed in above call.
            logWarning ""
            logWarning "Unable to create new test dataset variant."
            return 1
          else
            executableFrom=${downloadsExecutablesFolder}/${selectedExecutable}
            statecuExecutable=${statecuFolder}/$(basename ${executableFrom})
            nchars=$(echo ${statecuExecutable} | wc -c)
            if [ ${nchars} -gt 255 ]; then
              logWarning "StateCU executable name is > 255 characters."
              logWarning "Will not work on Windows or Linux."
              return 1
            fi
            logInfo ""
            logInfo "Copying executable:"
            logInfo "  from: ${executableFrom}"
            logInfo "    to: ${statecuExecutable}"
            cp "${executableFrom}" "${statecuExecutable}"
            if [ $? -eq 0 ]; then
               logInfo "Success copying executable file."
               # Also set the permissions to executable.
               logInfo "Setting StateCU program file permissions to executable (need in linux environments)."
               chmod a+x ${statecuExecutable} 2> /dev/null
               if [ $? -ne 0 ]; then
                 logWarning "${warnColor}Error setting executable permissions:${endColor}"
                 logWarning "${warnColor}  ${statecuExecutable}${endColor}"
                 logWarning "${warnColor}Check script code.${endColor}"
               fi
               return 0
            else
               logWarning "${warnColor}Error copying executable - check script code.${endColor}"
               return 1
            fi
          fi
          # Create the empty 'comp' folder for comparisons.
          # - this is also done when creating a new comp so hopefully works OK overall
          compFolder="${testDatasetFolder}/comp"
          if [ ! -d "${testDatasertFolder}" ]; then
            logInfo "Creating 'comp' folder for comparisons:"
            logInfo "  ${compFolder}"
            mkdir "${compFolder}"
            if [ $? -ne 0 ]; then
              logWarning "Error creating 'comp' folder:"
              logWarning "  ${compFolder}"
              logWarning "Check the script code."
              return 1
            fi
          fi
        fi
      done
    fi
  done
  return 0
}

# Parse the command line and set variables to control logic.
parseCommandLine() {
  local additionalOpts exitCode optstring optstringLong
  # Indicate specification for single character options:
  # - 1 colon after an option indicates that an argument is required
  # - 2 colons after an option indicates that an argument is optional, must use -o=argument syntax
  optstring="dhv"
  # Indicate specification for long options:
  # - 1 colon after an option indicates that an argument is required
  # - 2 colons after an option indicates that an argument is optional, must use --option=argument syntax
  optstringLong="debug,help,version"
  # Parse the options using getopt command:
  # - the -- is a separator between getopt options and parameters to be parsed
  # - output is simple space-delimited command line
  # - error message will be printed if unrecognized option or missing parameter but status will be 0
  # - if an optional argument is not specified, output will include empty string ''
  GETOPT_OUT=$(getopt --options ${optstring} --longoptions ${optstringLong} -- "$@")
  exitCode=$?
  if [ ${exitCode} -ne 0 ]; then
    echoStderr ""
    printUsage
    exit 1
  fi
  # The following constructs the command by concatenating arguments:
  # - the $1, $2, etc. variables are set as if typed on the command line
  # - special cases like --option=value and missing optional arguments are generically handled
  #   as separate parameters so shift can be done below
  eval set -- "${GETOPT_OUT}"
  # Loop over the options:
  # - the error handling will catch cases were argument is missing
  # - shift over the known number of options/arguments
  while true; do
    #echoStderr "Command line option is ${opt}"
    case "$1" in
      -d|--debug) # -d or --debug Turn on debug messages.
        debug="true"
        shift 1
        ;;
      -h|--help) # -h or --help  Print usage.
        printUsage
        exit 0
        ;;
      -v|--version) # -v or --version  Print the version.
        printVersion
        exit 0
        ;;
      --) # No more arguments.
        shift
        break
        ;;
      *) # Unknown option - will never get here because getopt catches up front.
        logError " "
        logError "Invalid option $1." >&2
        printUsage
        exit 1
        ;;
    esac
  done
  # Get a list of all command line options that do not correspond to dash options:
  # - These are "non-option" arguments.
  # - For example, one or more file or folder names that need to be processed.
  # - If multiple values, they will be delimited by spaces.
  # - Command line * will result in expansion to matching files and folders.
  shift $((OPTIND-1))
  additionalOpts=$*
  command="$1"
  if [ -n "${command}" ]; then
    case "${command}" in
      newdataset) # Create a new dataset folder.
        command="newDataset"
        logDebug "Detected 'newDataset' command."
        shift 1
        ;;
      *) # Unrecognized command.
        logError "Unrecognized command: ${command}"
        printUsage
        exit 1
        ;;
    esac
  fi
}

# Print help for a command:
# - the first argument is an optional menu command
printHelp() {
  local command helpLine

  command=$1

  helpLine="--------------------------------------------------------------------------------------"

  # List in order of the interactive menus.
  logText ""
  logText ${helpLine}
  logText "                                    Help"
  logText ${helpLine}
  # ==========================
  # Downloads
  # ==========================
  if [[ "${command}" = "lsdd"* ]]; then
    logText "${menuColor}lsdd${endColor}s"
    logText ""
    logText "List datasets in the downloads folder."
    logText "The datasets form the basis of tests."
    logText "Use TSTool to download and unzip datasets by running '*dataset*' command files in the folder:"
    logText "  ${downloadsFolder}"
    logText "Or, copy StateCU dataset zip files to the following folder:"
    logText "  ${downloadsDatasetsFolder}"
  elif [[ "${command}" = "lsde"* ]]; then
    logText "${menuColor}lsde${endColor}xe"
    logText ""
    logText "List executables in the downloads folder."
    logText "These are used for test dataset variants."
    logText "Use TSTool to download executables by running '*executable*' command files in the folder:"
    logText "  ${downloadsFolder}"
    logText "Or, copy StateCU executables to the following folder:"
    logText "  ${downloadsExecutablesFolder}"
  # ==========================
  # Test Datasets
  # ==========================
  elif [[ "${command}" = "lst"* ]]; then
    #logText "${menuColor}lst${endColor}est [dataset]"
    logText "${menuColor}lst${endColor}est"
    logText ""
    #logText "With no argument, list all test datasets, which match download dataset names."
    logText "List all test datasets, which match download dataset names."
    #logText "With a dataset (e.g., cm2015_StateCU), list test dataset variants for the dataset."
    #logText "The 'dataset' can contain wildcards (e.g., *cm*)."
    logText "Test dataset variant names match StateCU executable names."
  elif [[ "${command}" = "lsv"* ]]; then
    logText "${menuColor}lsv${endColor}ariant [*dataset*]"
    logText ""
    logText "With no argument, list all test datasets variants (dataset + executable)."
    logText "With a dataset (e.g., cm2015_StateCU), list test dataset variants for the dataset."
    logText "The 'dataset' can contain wildcards (e.g., *cm*)."
  elif [[ "${command}" = "newt"* ]]; then
    logText "${menuColor}newt${endColor}est"
    logText ""
    logText "Create a new test dataset from downloads."
    logText "Running the command provides instructions for how to use TSTool to create the dataset."
  elif [[ "${command}" = "newv"* ]]; then
    logText "${menuColor}newv${endColor}ariant"
    logText ""
    logText "Create a new test dataset variant."
    logText "Prompts are provided to select the dataset and executable."
    logText "Test dataset variants match StateCU executable names."
  elif [[ "${command}" = "rmt"* ]]; then
    logText "${menuColor}rmt${endColor}est"
    logText ""
    logText "Remove a test dataset (e.g., 'cm2015_StateCU'), all executable variants, and all comparisons."
    logText "A prompt is provided to confirm the removal."
    logText "If needed later, the dataset will need to be recreated from downloaded file."
  elif [[ "${command}" = "rmv"* ]]; then
    logText "${menuColor}rmv${endColor}ariant"
    logText ""
    logText "Remove a test dataset variant (matches executable name)."
    logText "A prompt is provided to confirm the removal."
    logText "If needed later, the dataset variant can be created."
  # ==========================
  # StateCU
  # ==========================
  elif [[ "${command}" = "runs"* ]]; then
    logText "${menuColor}runs${endColor}tatecu"
    logText ""
    logText "Run StateCU on a test dataset variant."
    logText "StateCU will be run on all response (*.rcu) files in the 'StateCU' folder."
    logText "The results can then be used for comparisons."
  # ==========================
  # Compare
  # ==========================
  elif [[ "${command}" = "lsc"* ]]; then
    logText "${menuColor}lsc${endColor}omp [*dataset*]"
    logText ""
    logText "With no argument, list all test datasets comparisons."
    logText "With a dataset (e.g., cm2015_StateCU), list test dataset comparisons for the dataset."
    logText "The 'dataset' can contain wildcards (e.g., *cm*)."
  elif [[ "${command}" = "newc"* ]]; then
    logText "${menuColor}newc${endColor}omp"
    logText ""
    logText "Create a new comparison by copying TSTool template file and updating for the dataset."
    logText "The comparison will need to be run using TSTool."
    logText "Creating a new comparison only needs to be done once (not after every model run)."
  elif [[ "${command}" = "runc"* ]]; then
    logText "${menuColor}runc${endColor}omp"
    logText ""
    logText "Run TSTool to do the comparison."
    logText "A comparison should be run after a model is (re)run to reflect changes in the model."
    logText "See the output files for a detailed list and summary of differences."
  elif [[ "${command}" = "v"* ]]; then
    logText "${menuColor}v${endColor}heatmap"
    logText ""
    logText "Run TSTool to view a heatmap of differences for a time series."
    logText "This is typically used to understand the details of differences."
  elif [[ "${command}" = "rmc"* ]]; then
    logText "${menuColor}rmc${endColor}omp"
    logText ""
    logText "Remove a test comparison."
    logText "A prompt is provided to confirm the removal."
  # ==========================
  # Handle issues.
  # ==========================
  elif [ -n "${command}" ]; then
    logText "${warnColor}Unknown command: ${command}${endColor}"
    logText "${warnColor}Can't print help.${endColor}"
  else
    logText "${warnColor}Specify a command after 'h' to print command help.${endColor}"
  fi
  logText ${helpLine}
  return 0
}

# Print the script usage:
# - calling code must exist with appropriate code
printUsage() {
  echoStderr ""
  echoStderr "========================================================================================================="
  echoStderr "Usage:  ${scriptName} [command] [option...]"
  echoStderr ""
  echoStderr "StateCU test manager program."
  echoStderr ""
  echoStderr "Examples of commands:"
  echoStderr "  ${scriptName} newdataset      Create a folder for a new dataset."
  echoStderr ""
  echoStderr "========================================================================================================="
  echoStderr "Commands (will run in batch mode and then exit):"
  echoStderr ""
  echoStderr "newdataset                      Configure a folder for a new dataset."
  echoStderr ""
  echoStderr "========================================================================================================="
  echoStderr "Command options:"
  echoStderr ""
  echoStderr "-d, --debug                     Turn debug on."
  echoStderr "-h, --help                      Print the usage."
  echoStderr "-v, --version                   Print the version."
  echoStderr ""
  echoStderr "========================================================================================================="
  echoStderr "All logging messages are printed to stderr."
  echoStderr "========================================================================================================="
  echoStderr ""
}

# Print the script version:
# - calling code must exist with appropriate code
printVersion() {
  echoStderr "${scriptName} version ${version}"
}

# Remove a test datasets:
# - for example `cm2015_StateCU'
# - prompt for the dataset
removeTestDataset() {
  local selectedDataset selectedDatasetNumber
  local ndatasets

  logText ""
  logText "Remove a dataset (e.g., cm2015_StateCU) and all test variants."
  logText ""

  # Make sure that the program is not in a folder to be removed:
  # - just change to the initial ${scriptFolder}
  cd ${scriptFolder}

  listTestDatasets numbered
  ndatasets=$?
  if [ "${ndatasets}" -eq 0 ]; then
    logInfo ""
    logInfo "There are no datasets.  Need to download and install datasets."
    return 0
  fi
  logText ""
  read -p "Select the number of the dataset to remove (#/q/ ): " selectedDatasetNumber
  if [ "${selectedDatasetNumber}" = "q" -o "${selectedDatasetNumber}" = "Q" ]; then
    exit 0
  elif [ -z "${selectedDatasetNumber}" ]; then
    # Don't want to continue.
    return
  else
    # Remove the dataset.
    selectedDataset=$(listTestDatasets | head -${selectedDatasetNumber} | tail -1)
    logText "Selected dataset: ${selectedDataset}"
    testDatasetFolder="${testDatasetsFolder}/${selectedDataset}"
    logText "Removing:"
    logText "  ${testDatasetFolder}"
    read -p "Confirm delete dataset (Y/n/q)? " answer
    if [ "${answer}" = "q" -o "${answer}" = "Q" ]; then
      exit 0
    elif [ -z "${answer}" -o "${answer}" = "y" -o "${answer}" = "Y" ]; then
      rm -rf ${testDatasetFolder}
      if [ $? -eq 0 ]; then
        logInfo "${okColor}Successfully deleted dataset.${endColor}"
      else
        logWarning "${warnColor}Error deleting dataset.${endColor}"
        logWarning "${warnColor}Files may be opened in software or command line session may be in folder.${endColor}"
      fi
    else
      return 0
    fi
  fi
  return 0
}

# Remove a test dataset comparison:
# - prompt for the comparison
# - this code is a copy of removeTestDatasetVariant() but uses 'comps' instead of 'exes'
removeTestDatasetComp() {
  local ndatasets selectedDataset selectedDatasetNumber

  logText ""
  logText "Remove a dataset comparison that matches an executable name."
  logText "The following are available comparisons (~ is used in names to separate dataset and executable names)."
  logText ""

  listTestDatasetComps numbered
  ndatasets=$?
  if [ "${ndatasets}" -eq 0 ]; then
    logInfo ""
    logInfo "There are no test dataset comparisons."
    return 0
  fi

  # Make sure that the program is not in a folder to be removed:
  # - just change to the initial ${scriptFolder}
  cd ${scriptFolder}

  # The list will include dataset/variant.
  logText ""
  read -p "Select the number of the dataset comparison to remove (#/q/ ): " selectedDatasetNumber
  if [ "${selectedDatasetNumber}" = "q" -o "${selectedDatasetNumber}" = "Q" ]; then
    exit 0
  elif [ -z "${selectedDatasetNumber}" ]; then
    # Don't want to continue.
    return
  else
    # Remove the dataset comparison.
    selectedDataset=$(listTestDatasetComps | head -${selectedDatasetNumber} | tail -1)
    logText "Selected dataset comparison: ${selectedDataset}"
    testDatasetFolder="${testDatasetsFolder}/${selectedDataset}"
    logText "Removing:"
    logText "  ${testDatasetFolder}"
    read -p "Confirm delete dataset comparison (Y/n/q)? " answer
    if [ "${answer}" = "q" -o "${answer}" = "Q" ]; then
      exit 0
    elif [ -z "${answer}" -o "${answer}" = "y" -o "${answer}" = "Y" ]; then
      rm -rf ${testDatasetFolder}
      if [ ! -d "${testDatasetFolder}" ]; then
        logInfo "${okColor}Successfully deleted dataset comparison.${endColor}"
      else
        logWarning "${warnColor}Error deleting dataset comparison.${endColor}"
        logWarning "${warnColor}Files may be opened in software or command line session may be in folder.${endColor}"
      fi
    else
      return 0
    fi
  fi
  return 0
}

# Remove a test dataset variant:
# - matches an executable name
# - prompt for the dataset
removeTestDatasetVariant() {
  local ndatasets selectedDataset selectedDatasetNumber

  logText ""
  logText "Remove a dataset variant that matches an executable name."
  logText ""

  listTestDatasetVariants numbered
  ndatasets=$?
  if [ "${ndatasets}" -eq 0 ]; then
    logInfo ""
    logInfo "There are no test dataset variants."
    return 0
  fi

  # Make sure that the program is not in a folder to be removed:
  # - just change to the initial ${scriptFolder}
  cd ${scriptFolder}

  # The list will include dataset/variant.
  logText ""
  read -p "Select the number of the dataset variant to remove (#/q/ ): " selectedDatasetNumber
  if [ "${selectedDatasetNumber}" = "q" -o "${selectedDatasetNumber}" = "Q" ]; then
    exit 0
  elif [ -z "${selectedDatasetNumber}" ]; then
    # Don't want to continue.
    return
  else
    # Remove the dataset.
    selectedDataset=$(listTestDatasetVariants | head -${selectedDatasetNumber} | tail -1)
    logText "Selected dataset variant: ${selectedDataset}"
    testDatasetFolder="${testDatasetsFolder}/${selectedDataset}"
    logText "Removing:"
    logText "  ${testDatasetFolder}"
    read -p "Confirm delete dataset variant (Y/n/q)? " answer
    if [ "${answer}" = "q" -o "${answer}" = "Q" ]; then
      exit 0
    elif [ -z "${answer}" -o "${answer}" = "y" -o "${answer}" = "Y" ]; then
      rm -rf ${testDatasetFolder}
      if [ $? -eq 0 ]; then
        logInfo "${okColor}Successfully deleted dataset variant.${endColor}"
      else
        logWarning "${warnColor}Error deleting dataset variant.${endColor}"
        logWarning "${warnColor}Files may be opened in software or command line session may be in folder.${endColor}"
      fi
    else
      return 0
    fi
  fi
  return 0
}

# Run interactively:
# - use simple echo without logging
runInteractive () {
  local answer command dataset

  dataset=""
  lineEquals="================================================================================================"

  while [ "1" = "1" ]; do
    # Remove blank links when other items are added to provide separation.
    ${echo2} ""
    #${echo2} "================================================================================================"
    #${echo2} "Current dataset:  ${dataset}"
    ${echo2} "${lineEquals}"
    ${echo2} "Downloads...${menuColor}lsdd${endColor}s                  - list downloaded datasets"
    ${echo2} "            ${menuColor}lsde${endColor}xe                 - list downloaded executables"
    ${echo2} ""
    ${echo2} "Test........${menuColor}lst${endColor}est                 - list test datasets"
    ${echo2} "Datasets    ${menuColor}lsv${endColor}ariant [*dataset*]  - list test variants (for dataset and executable)"
    ${echo2} "            ${menuColor}newt${endColor}est                - create a new test dataset from downloads"
    ${echo2} "            ${menuColor}newv${endColor}ariant             - create a new test variant for a dataset and executable"
    ${echo2} "            ${menuColor}rmt${endColor}est                 - remove test dataset folder (e.g., cm2015_StateCU)"
    ${echo2} "            ${menuColor}rmv${endColor}ariant              - remove test dataset variant folder (for executable variant)"
    ${echo2} ""
    ${echo2} "StateCU.....${menuColor}runs${endColor}tatecu             - run StateCU on a test dataset variant (dataset + executable)"
    ${echo2} ""
    ${echo2} "Compare.....${menuColor}lsc${endColor}omp [*dataset*]     - list test dataset comparisons"
    ${echo2} "            ${menuColor}newc${endColor}omp                - create a comparison for 2 dataset test variants"
    ${echo2} "            ${menuColor}runc${endColor}omp                - run a dataset variant scenario comparison using TSTool"
    ${echo2} "            ${menuColor}v${endColor}heatmap               - view a heatmap for a time series' differences"
    ${echo2} "            ${menuColor}rmc${endColor}omp                 - remove a comparison"
    ${echo2} "${lineEquals}"
    ${echo2} "            ${menuColor}q${endColor}uit"
    ${echo2} "            ${menuColor}h${endColor}elp [command]"
    ${echo2} ""
    read -p "Enter menu item: " answer
    # ======================
    # Downloads
    # ======================
    if [[ "${answer}" = "lsdd"* ]]; then
      listDownloadDatasets indented
    elif [[ "${answer}" = "lsde"* ]]; then
      listDownloadExecutables indented
    # ======================
    # Test Datasets
    # ======================
    elif [[ "${answer}" = "lst"* ]]; then
      # List the datasets or the contents of a dataset's folder:
      # - specifying a dataset is essentially the same as listing the variant so hide for now
      answerWordCount=$(echo ${answer} | wc -w)
      logText ""
      if [ "${answerWordCount}" -eq 2 ]; then
        # Menu item followed by dataset name.
        dataset=$(echo ${answer} | cut -d ' ' -f 2)
        logText "Test dataset (${dataset}) executable variants:"
      else
        # Assume just menu item so default dataset.
        dataset=""
        logText "Test datasets:"
      fi
      logText ""
      listTestDatasets indented ${dataset}
    elif [[ "${answer}" = "lsv"* ]]; then
      # List the datasets or the contents of a dataset's folder.
      answerWordCount=$(echo ${answer} | wc -w)
      logText ""
      if [ "${answerWordCount}" -eq 2 ]; then
        # Menu item followed by dataset name.
        dataset=$(echo ${answer} | cut -d ' ' -f 2)
        logText "Test dataset (${dataset}) executable variants:"
      else
        # Assume just menu item so default dataset.
        dataset=""
        logText "Test dataset variants (dataset + executable) for all datasets:"
      fi
      logText ""
      listTestDatasetVariants indented ${dataset}
    # ======================
    elif [[ "${answer}" = "newt"* ]]; then
      # Create a new test dataset:
      newTestDataset
    elif [[ "${answer}" = "newv"* ]]; then
      # Create a new test dataset variant:
      # - the test variant will match an executable name
      newTestDatasetVariant
    elif [[ "${answer}" = "rmt"* ]]; then
      # Remove a dataset test:
      removeTestDataset
    elif [[ "${answer}" = "rmv"* ]]; then
      # Remove a dataset test variant:
      removeTestDatasetVariant
    # ======================
    # StateCU
    # ======================
    elif [[ "${answer}" = "runs"* ]]; then
      # Run a dataset in the testing framework:
      # - for example dataset is 'cm2015'
      answerWordCount=$(echo ${answer} | wc -w)
      if [ "${answerWordCount}" -eq 2 ]; then
        # Menu item followed by dataset name.
        dataset=$(echo ${answer} | cut -d ' ' -f 2)
      else
        # Assume just menu item so default dataset.
        dataset=""
      fi
      runTestDatasetVariant ${dataset}
    # ======================
    # Compare
    # ======================
    elif [[ "${answer}" = "lsc"* ]]; then
      # List the dataset comparisons.
      answerWordCount=$(echo ${answer} | wc -w)
      logText ""
      if [ "${answerWordCount}" -eq 2 ]; then
        # Menu item followed by dataset name.
        dataset=$(echo ${answer} | cut -d ' ' -f 2)
        logText "Test dataset (${dataset}) comparisons:"
      else
        # Assume just menu item so default dataset.
        dataset=""
        logText "Test dataset comparisons for all datasets:"
      fi
      logText ""
      listTestDatasetComps indented ${dataset}
    elif [[ "${answer}" = "newc"* ]]; then
      # Create a new test dataset comparison:
      # - the comparison will match two variants
      newTestDatasetComp
    elif [[ "${answer}" = "runc"* ]]; then
      # Run TSTool to create a dataset comparison.
      runTestDatasetComp
    elif [[ "${answer}" = "v"* ]]; then
      # Run TSTool to create a heatmap visualization.
      viewCompDifferenceHeatmap
    elif [[ "${answer}" = "rmc"* ]]; then
      removeTestDatasetComp
    # ======================
    # General commands
    # ======================
    elif [[ "${answer}" = "h"* ]]; then
      # List print help.
      answerWordCount=$(echo ${answer} | wc -w)
      if [ "${answerWordCount}" -eq 2 ]; then
        # Menu item followed by count.
        command=$(echo ${answer} | cut -d ' ' -f 2)
      else
        # No command
        command=""
      fi
      printHelp "${command}"
    elif [[ "${answer}" = "q"* ]]; then
      # Quit.
      exit 0
    elif [ -z "${answer}" ]; then
      # Display the menu again.
      continue
    else
      # Unknown option, show the message again.
      echo "Don't know how to handle command:  ${answer}"
    fi
  done
}

# Run a test dataset comparison using TSTool.
runTestDatasetComp() {
  local doBackground

  # Select a comparison to run.

  logText ""
  logText "Run a dataset variant comparison using TSTool."

  logText ""
  logText "Available dataset variant comparisons (you will be prompted for a scenario):"
  logText ""
  listTestDatasetComps numbered
  ncomps=$?
  if [ "${ncomps}" -eq 0 ]; then
    logInfo ""
    logInfo "There are no test dataset comparisons.  Need to create a test dataset comparison."
    return 0
  fi

  # The list will include be of the form:
  #   cm2015_StateCU/comps/x-statecu-14.0.0-gfortran-win-64bit~statecu-13.10-gfortran-win-32bit
  logText ""
  read -p "Select the number of the comparison to run (#/q/ ): " selectedCompNumber
  if [ "${selectedCompNumber}" = "q" -o "${selectedCompNumber}" = "Q" ]; then
    exit 0
  elif [ -z "${selectedCompNumber}" ]; then
    # Don't want to continue.
    return
  else
    # Run the comparison.
    selectedComp=$(listTestDatasetComps | head -${selectedCompNumber} | tail -1)
    logText "Selected dataset variant comparison: ${selectedComp}"
    testCompFolder="${testDatasetsFolder}/${selectedComp}"
    if [ ! -d "${testCompFolder}" ]; then
      logWarning "Test dataset comp folder does not exist: ${testCompFolder}"
      logWarning "Check script code."
      logWarning "Cannot run comparison using TSTool."
      return 1
    fi

    # Get the parts from the path needed for TSTool command file.
    # - an example comparison folder path is:
    #   /c/Users/sam/cdss-dev/StateCU/git-repos/cdss-app-statecu-fortran-test/test/datasets/cm2015_StateCU/comps/statecu-14.0.0-gfortran-win-64bit~statecu-13.10-gfortran-win-32bit
    # - ${datasetName} is used for the StateCU "scenario" used for the response file name
    # - ${datasetVariantName1} is used to determine the variant folder, with StateCU folder passed to TSTool
    datasetName=$(echo ${testCompFolder} | awk -F/ '{print $(NF -2)}')
    if [ -z "${datasetName}" ]; then
      logWarning "${warnColor}Could not determine Scenario for TSTool.${endColor}"
      return 1
    fi

    # Get the full path to dataset variants.

    datasetVariantName1=$(echo ${testCompFolder} | awk -F/ '{print $NF}' | cut -d '~' -f 1)
    datasetVariantFolder1=${testDatasetsFolder}/${datasetName}/exes/${datasetVariantName1}
    if [ ! -d "${datasetVariantFolder1}" ]; then
      logWarning "${warnColor}Could not determine Dataset1Folder for TSTool.${endColor}"
      return 1
    fi

    datasetVariantName2=$(echo ${testCompFolder} | awk -F/ '{print $NF}' | cut -d '~' -f 2)
    datasetVariantFolder2=${testDatasetsFolder}/${datasetName}/exes/${datasetVariantName2}
    if [ ! -d "${datasetVariantFolder2}" ]; then
      logWarning "${warnColor}Could not determine Dataset2Folder for TSTool.${endColor}"
      return 1
    fi

    # Determine the StateCU folder, which contains the binary output and other files.
    datasetStatecuFolder1=$(getTestDatasetVariantStatecuFolder ${datasetVariantFolder1})
    if [ $? -ne 0 -o -z "${datasetStatecuFolder1}" ]; then
      logWarning ""
      logWarning "${warnColor}Unable to determine StateCU folder for dataset:${endColor}"
      logWarning "${warnColor}  ${datasetVariantFolder1}${endColor}"
      return 1
    fi
    datasetStatecuFolder2=$(getTestDatasetVariantStatecuFolder ${datasetVariantFolder2})
    if [ $? -ne 0 -o -z "${datasetStatecuFolder2}" ]; then
      logWarning ""
      logWarning "${warnColor}Unable to determine StateCU folder for dataset:${endColor}"
      logWarning "${warnColor}  ${datasetVariantFolder2}${endColor}"
      return 1
    fi

    # Prompt for the response file to use for the scenario:
    # - assuming that each folder contains the same dataset files, which should be true,
    #   get the list of response files
    logText ""
    logText "Available scenarios for dataset ${datasetName}:"
    logText ""
    listTestDatasetVariantScenarios numbered ${datasetStatecuFolder1}
    logText ""
    read -p "Select a dataset scenario (#/q/ ): " selectedScenarioNumber
    if [ "${selectedScenarioNumber}" = "q" -o "${selectedScenarioNumber}" = "Q" ]; then
      exit 0
    elif [ -z "${selectedScenarioNumber}" ]; then
      # Don't want to continue.
      return 0
    else
      # Have a scenario number.
      selectedScenario=$(listTestDatasetVariantScenarios ${datasetStatecuFolder1} | head -${selectedScenarioNumber} | tail -1)
    fi

    logInfo "TSTool command line includes:  Dataset1Folder==${datasetStatecuFolder1}"
    logInfo "TSTool command line includes:  Dataset2Folder==${datasetStatecuFolder2}"
    logInfo "TSTool command line includes:  Scenario==${selectedScenario}"

    tstoolCommandFile="${testCompFolder}/compare-statecu-runs.tstool"
    logInfo ""
    logInfo "Running comparison using TSTool command file:"
    logInfo "  ${tstoolCommandFile}"
    if [ ! -f "${tstoolCommandFile}" ]; then
      logWarning ""
      logWarning "${warnColor}TSTool command file does not exist:${endColor}"
      logWarning "${warnColor}  ${tstoolCommandFile}${endColor}"
      return 1
    fi

    # Run TSTool:
    # - the executable location was determined at script startup
    # - pass configuration properties in on the command line so that the template file can be used without modification
    # - run in the background so can have multiple sessions/visualizations going at the same time,
    #   although this does use more memory on the computer
    # - checking the exit status on background processes may be tricky
    if [ ! -f "${tstoolExe}" ]; then
      logWarning ""
      logWarning "${warnColor}TSTool program does not exist:${endColor}"
      logWarning "${warnColor}${tstoolExe}${endColor}"
      return 1
    fi

    doBackground="true"
    if [ "${doBackground}" = "true" ]; then
      logInfo "${menuColor}Running TSTool in the background so that other tasks can be run.${endColor}"
      logInfo "${menuColor}TSTool messages may be written as it runs.${endColor}"
      logInfo "${menuColor}If necessary, press return to view the menu.${endColor}"
      # Give a little time to see the above.
      sleep 1
      ${tstoolExe} -- ${tstoolCommandFile} Dataset1Folder==${datasetStatecuFolder1} Dataset2Folder==${datasetStatecuFolder2} Scenario==${selectedScenario}&
      # Can't get the return status here.
      return 0
    else
      logInfo "${menuColor}Running TSTool before continuing.${endColor}"
      ${tstoolExe} -- ${tstoolCommandFile} Dataset1Folder==${datasetStatecuFolder1} Dataset2Folder==${datasetStatecuFolder2} Scenario==${selectedScenario}
      if [ $? -ne 0 ]; then
        logWarning ""
        logWarning "${warnColor}Error running TSTool.${endColor}"
        return 1
      fi
    fi
  fi
  return 0
}

# Run a test dataset variant:
# - matches an executable name
# - prompt for the dataset
runTestDatasetVariant() {
  local ndatasets selectedDataset selectedDatasetNumber
  local selectedRcu selectedRcuNumber
  local rcuCount rcuFile rcuFileNoExt
  local statecuFolder statecuExecutable statecuExecutableNoExt

  logText ""
  logText "Run a dataset variant that matches an executable name."
  logText "All scenarios (*.rcu) for the dataset variant will be run."
  logText "Available dataset variants:"
  logText ""

  listTestDatasetVariants numbered
  ndatasets=$?
  if [ "${ndatasets}" -eq 0 ]; then
    logInfo ""
    logInfo "There are no test dataset variants.  Need to create a test dataset with executable variant."
    return 0
  fi

  # The list will include dataset/variant.
  logText ""
  read -p "Select the number of the dataset variant to run (#/q/ ): " selectedDatasetNumber
  if [ "${selectedDatasetNumber}" = "q" -o "${selectedDatasetNumber}" = "Q" ]; then
    exit 0
  elif [ -z "${selectedDatasetNumber}" ]; then
    # Don't want to continue.
    return
  else
    # Run the dataset.
    selectedDataset=$(listTestDatasetVariants | head -${selectedDatasetNumber} | tail -1)
    logText "Selected dataset variant: ${selectedDataset}"
    testVariantFolder="${testDatasetsFolder}/${selectedDataset}"
    if [ ! -d "${testVariantFolder}" ]; then
      logWarning "Test dataset variant folder does not exist: ${testVariantFolder}"
      logWarning "Check script code."
      logWarning "Cannot run StateMod."
      return 1
    fi

    # Change to the StateCU folder to run the model.
    statecuFolder=$(getTestDatasetVariantStatecuFolder ${testVariantFolder})
    if [ $? -ne 0 -o -z "${statecuFolder}" ]; then
      # Warnings will have been printed in above call.
      logWarning ""
      logWarning "${warnColor}Unable to run StateCU.${endColor}"
      return 1
    fi
    # Determine the StateCU executable name using conventions:
    # - StateCU executable on linux won't have the extension
    # - on Windows can run without the extension but checking with extension
    #   confirms that the file exists
    statecuExecutableNoExt="${statecuFolder}/$(basename ${testVariantFolder})"
    statecuExecutable="${statecuFolder}/$(basename ${testVariantFolder}.exe)"
    logInfo ""
    logInfo "Changing to dataset variant folder:"
    logInfo "  ${statecuFolder}"
    cd ${statecuFolder}
    if [ $? -ne 0 ]; then
      logWarning "${warnColor}Could not cd to StateCU folder:${endColor}"
      logWarning "${warnColor}  ${statecuFolder}${endColor}"
      logWarning "${warnColor}Cannot run StateCU.  Permissions problem?${endColor}"
      return 1
    fi
    # Check other requirements.
    if [ ! -f "${statecuExecutable}" -a ! -f "${statecuExecutableNoExt}" ]; then
      # Neither executable name exists:
      # - should have been copied when the dataset was created
      logWarning "${warnColor}StateCU executable does not exist:${endColor}"
      logWarning "${warnColor}  ${statecuExecutable}${endColor}"
      logWarning "${warnColor}  ${statecuExecutableNoExt}${endColor}"
      logWarning "${warnColor}Cannot run StateCU.  Check dataset setup.${endColor}"
      return 1
    elif [ -f "${statecuExecutable}" -a ! -x "${statecuExecutable}" ]; then
      # StateCU program is not executable:
      # - should have been set when the dataset was created
      logWarning "${warnColor}StateCU executable permissions are not executable:${endColor}"
      logWarning "${warnColor}  ${statecuExecutable}${endColor}"
      logWarning "${warnColor}Cannot run StateCU.  Check dataset setup.${endColor}"
      return 1
    elif [ -f "${statecuExecutableNoExt}" -a ! -x "${statecuExecutableNoExt}" ]; then
      # StateCU program is not executable:
      # - should have been set when the dataset was created
      logWarning "${warnColor}StateCU executable permissions are not executable:${endColor}"
      logWarning "${warnColor}  ${statecuExecutableNoExt}${endColor}"
      logWarning "${warnColor}Cannot run StateCU.  Check dataset setup.${endColor}"
      return 1
    else
      # Run StateCU for all *.rcu files that are available.
      # Get the 'rcu' file to know what specific dataset to run.
      rcuCount=$('ls' -1 *.rcu | wc -l)
      logInfo "Found ${rcuCount} *.rcu files.  Will run each."
      if [ ${rcuCount} -eq 0 ]; then
        logWarning "No *.rcu file exists.  Cannot run StateCU."
        return 1
      fi
      # List into an array.
      #rcuFiles=$('ls' -1 *.rcu)
      for rcuFile in ${statecuFolder}/*.rcu; do
        # If here have the selected *.rcu file to run:
        # - run using the response file name without extension since that is the
        #   behavior that older StateCU versions support
        # - use the full path to the executable to avoid any possible conflict with PATH
        # - Windows and linux allow 255 characters for filename
        # - Windows command line can be up to 8191 and is longer in linux
        rcuFileName=$(basename ${rcuFile})
        rcuFileNoExt="${rcuFileName%.*}"
        logInfo "Running StateCU (the full path to the executable is used to ensure that the correct version is run):"
        logInfo "  ${statecuExecutable} ${rcuFileNoExt}"
        ${statecuExecutable} ${rcuFileNoExt}
        if [ $? -eq 0 ]; then
          logInfo "${okColor}Success running StateCU for: ${rcuFileNoExt}${endColor}"
        else
          logWarning "${warnColor}Error running StateCU for: ${rcuFileNoExt}${endColor}"
          logWarning "${warnColor}See the StateCU log file mentioned above.${endColor}"
        fi
      done
    fi
  fi
  return 0
}

# Set the path to the TSTool executable:
# - the ${tstoolExe} variable can then be used to run TSTool
# - since running in MinGW, use linux shell script to run TSTool,
#   which is more flexible than the Windows TSTool.exe
# - multiple drives are searched to find TSTool
# - if someone has installed in a nonstandard location that will be a problem
setTstoolExe() {
  local cdssFolder cdssFolderCount
  local drive driveList
  local tstoolFolder tstoolFolderCount
  local majorVersion tstoolExeTry

  # Uncomment the following to hard code for testing:
  # - this is the linux run script, which works in MinGW environment
  #tstoolExe="/c/CDSS/TSTool-14.0.0.dev2/bin/tstool"

  # Initialize.

  tstoolExe=""

  # Use for troubleshooting.
  #logInfo "Test listing:"
  #cdssFolder="/C/CDSS"
  #listTstoolFolders ${cdssFolder}

  # CDSS software may be installed on drives other than /C so loop through to find TSTool.
  driveList=( c d e f g h i j k l m n o p q r s t u v w x y z)
  cdssFolderCount=0
  for drive in "${driveList[@]}"; do
    cdssFolder="/${drive}/CDSS"
    logInfo "Searching for TSTool in: ${cdssFolder}"
    if [ -d "${cdssFolder}" ]; then
      # Have a CDSS folder that MIGHT contain TSTool:
      # - it could also just be a project or data folder
      # - increment the counter so can do a warning at the end
      cdssFolderCount=$((${cdssFolderCount} + 1))

      # Don't know for sure what the latest TSTool version is:
      # - if there are at least one that matches the pattern, then assume CDSS software location is found
      tstoolFolderCount=$(listTstoolFolders ${cdssFolder} 2> /dev/null | wc -l)
      if [ ${tstoolFolderCount} -ne 0 ]; then
        # Have something:
        # - assume this is where CDSS TSTool is installed
        # - get the newest version
        # - have to list by padding the version parts to ensure that 001 comes before 011
        # - won't check any other versions
        
        tstoolFolder=$(listTstoolFolders ${cdssFolder} 2> /dev/null | head -1)
        logInfo "tstoolFolder=${tstoolFolder}"

        # Make sure that the version is at least 14 (or whatever is required for the current script version):
        # - the listing output is similar to:
        #      /c/CDSS/TSTool-14.0.0.dev2
        #      /c/CDSS/TSTool-13.04.00
        # - check the major version part
        majorVersion=$(echo ${tstoolFolder} | cut -d '-' -f 2 | cut -d '.' -f 1)
        logInfo "majorVersion=${majorVersion}"
        if [ "${majorVersion}" -ge 14 ]; then
          # OK to use, else may not have any valid versions at the end.
          tstoolExeTry="${tstoolFolder}/bin/tstool"
          if [ -f "${tstoolExeTry}" ]; then
            # Found the executable:
            # - set it in global data
            tstoolExe=${tstoolExeTry}
            logInfo "TSTool executable is: ${tstoolExe}"
            return 0
          else
            logDebug "TSTool program does not exist:"
            logDebug "  ${tstoolExeTry}"
          fi
        fi
      fi
    fi
  done

  if [ "${cdssFolderCount}" -eq 0 ]; then
    logError ""
    logError "${errorColor}Cannot find installed TSTool software - exiting.${endColor}"
    logError "${errorColor}Install TSTool version 14+ to use this script.${endColor}"
    logError "${errorColor}If CDSS software is installed in a nonstandard location,${endColor}"
    logError "${errorColor}contact support to update this script.${endColor}"
    exit 1
  fi
}

# View a heat map (raster graph) of time series differences
viewCompDifferenceHeatmap() {
  local doBackground

  # Select a comparison to run.

  logText ""
  logText "View a time series difference heatmap using TSTool."
  logText "Available dataset comparisons are listed below."
  logText ""

  listTestDatasetComps numbered
  ncomps=$?
  if [ "${ncomps}" -eq 0 ]; then
    logInfo ""
    logInfo "There are no test dataset comparisons.  Need to create a test dataset comparison."
    return 0
  fi

  # The list will include be of the form:
  #   cm2015_StateCU/comps/x-statecu-14.0.0-gfortran-win-64bit~statecu-13.10-gfortran-win-32bit
  logText ""
  read -p "Select the number of the comparison (#/q/ ): " selectedCompNumber
  if [ "${selectedCompNumber}" = "q" -o "${selectedCompNumber}" = "Q" ]; then
    exit 0
  elif [ -z "${selectedCompNumber}" ]; then
    # Don't want to continue.
    return
  else
    # Run the comparison.
    selectedComp=$(listTestDatasetComps | head -${selectedCompNumber} | tail -1)
    logText "Selected comparison: ${selectedComp}"
    testCompFolder="${testDatasetsFolder}/${selectedComp}"
    if [ ! -d "${testCompFolder}" ]; then
      logWarning "Test dataset comp folder does not exist: ${testCompFolder}"
      logWarning "Check script code."
      logWarning "Cannot run comparison using TSTool."
      return 1
    fi

    # Get the parts from the path needed for TSTool command file.
    # - an example comparison folder path is:
    #   /c/Users/sam/cdss-dev/StateCU/git-repos/cdss-app-statecu-fortran-test/test/datasets/cm2015_StateCU/comps/statecu-14.0.0-gfortran-win-64bit~statecu-13.10-gfortran-win-32bit
    # - ${datasetName} is used for the StateCU "scenario" used for the response file name
    # - ${datasetVariantName1} is used to determine the variant folder, with StateCU folder passed to TSTool
    datasetName=$(echo ${testCompFolder} | awk -F/ '{print $(NF -2)}')
    if [ -z "${datasetName}" ]; then
      logWarning "${warnColor}Could not determine Scenario for TSTool.${endColor}"
      return 1
    fi

    # Get the full path to dataset variants.

    datasetVariantName1=$(echo ${testCompFolder} | awk -F/ '{print $NF}' | cut -d '~' -f 1)
    datasetVariantFolder1=${testDatasetsFolder}/${datasetName}/exes/${datasetVariantName1}
    if [ ! -d "${datasetVariantFolder1}" ]; then
      logWarning "${warnColor}Could not determine Dataset1Folder for TSTool.${endColor}"
      return 1
    fi

    datasetVariantName2=$(echo ${testCompFolder} | awk -F/ '{print $NF}' | cut -d '~' -f 2)
    datasetVariantFolder2=${testDatasetsFolder}/${datasetName}/exes/${datasetVariantName2}
    if [ ! -d "${datasetVariantFolder2}" ]; then
      logWarning "${warnColor}Could not determine Dataset2Folder for TSTool.${endColor}"
      return 1
    fi

    # Determine the StateCU folder, which contains the binary output and other files.
    datasetStatecuFolder1=$(getTestDatasetVariantStatecuFolder ${datasetVariantFolder1})
    if [ $? -ne 0 -o -z "${datasetStatecuFolder1}" ]; then
      logWarning ""
      logWarning "${warnColor}Unable to determine StateCU folder for dataset:${endColor}"
      logWarning "${warnColor}  ${datasetVariantFolder1}${endColor}"
      return 1
    fi
    datasetStatecuFolder2=$(getTestDatasetVariantStatecuFolder ${datasetVariantFolder2})
    if [ $? -ne 0 -o -z "${datasetStatecuFolder2}" ]; then
      logWarning ""
      logWarning "${warnColor}Unable to determine StateCU folder for dataset:${endColor}"
      logWarning "${warnColor}  ${datasetVariantFolder2}${endColor}"
      return 1
    fi

    # Prompt for the response file to use for the scenario:
    # - assuming that each folder contains the same dataset files, which should be true,
    #   get the list of response files
    logText ""
    logText "Available scenarios for dataset ${datasetName}:"
    logText ""
    listTestDatasetVariantScenarios numbered ${datasetStatecuFolder1}
    logText ""
    read -p "Select a dataset scenario (#/q/ ): " selectedScenarioNumber
    if [ "${selectedScenarioNumber}" = "q" -o "${selectedScenarioNumber}" = "Q" ]; then
      exit 0
    elif [ -z "${selectedScenarioNumber}" ]; then
      # Don't want to continue.
      return 0
    else
      # Have a scenario number.
      selectedScenario=$(listTestDatasetVariantScenarios ${datasetStatecuFolder1} | head -${selectedScenarioNumber} | tail -1)
    fi

    # Prompt for the time series to use for the visualization:
    # - get the list from the TSTool CompareTimeSeries summary output file
    logText ""
    logText "Time series with differences for dataset ${datasetName}:"
    logText ""
    listTestDatasetCompTimeSeries numbered ${testCompFolder}/results/${selectedScenario}-summary-differences.txt
    logText ""
    read -p "Select a time series (#/q/ ): " selectedTsNumber
    if [ "${selectedTsNumber}" = "q" -o "${selectedTsNumber}" = "Q" ]; then
      exit 0
    elif [ -z "${selectedTsNumber}" ]; then
      # Don't want to continue.
      return 0
    else
      # Have a scenario number.  Get the selected TSID.
      selectedTsid=$(listTestDatasetCompTimeSeries ${testCompFolder}/results/${selectedScenario}-summary-differences.txt | head -${selectedTsNumber} | tail -1)
    fi

    # The following will break if data contain dashes.
    logInfo "selecteTsid=${selectedTsid}"

    # Trim surrounding whitespace but keep within values:
    # - actually, replace inner spaces with ___ (3 underscores) because spaces in the command line cause issues
    # - then use the TSTool --space-replacement command line option
    tsid=$(echo ${selectedTsid} | awk -F- '{
      sub(/^[ \t]+/,"",$1);
      sub(/[ \t]+$/,"",$1);
      print $1
    }' | sed 's/ /___/g')
    tsDescription=$(echo ${selectedTsid} | awk -F- '{
      sub(/^[ \t]+/,"",$2);
      sub(/[ \t]+$/,"",$2);
      print $2
    }' | sed 's/ /___/g')

    logInfo "TSTool command line includes:  Scenario==${selectedScenario}"
    logInfo "TSTool command line includes:  Description==${tsDescription}"
    logInfo "TSTool command line includes:  TSID==${tsid}"

    # Make sure the difference time series data file exists.
    diffDataFile="${testCompFolder}/results/${selectedScenario}-ts-diff.dv"
    if [ ! -f "${diffDataFile}" ]; then
      logWarning ""
      logWarning "${warnColor}Comparison difference data file does not exist:${endColor}"
      logWarning "${warnColor}  ${diffDataFile}${endColor}"
      logWarning "${warnColor}Make sure to run the comparison before trying to visualize results.${endColor}"
      return 1
    fi

    # Run TSTool.

    tstoolCommandFile="${testCompFolder}/ts-diff.tstool"
    logInfo ""
    logInfo "Running diff-ts visualization using TSTool command file:"
    logInfo "  ${tstoolCommandFile}"
    if [ ! -f "${tstoolCommandFile}" ]; then
      logWarning ""
      logWarning "${warnColor}TSTool command file does not exist:${endColor}"
      logWarning "${warnColor}  ${tstoolCommandFile}${endColor}"
      return 1
    fi

    # Run TSTool:
    # - the executable location was determined at script startup
    # - pass configuration properties in on the command line so that the template file can be used without modification
    # - use the --space-replacement option
    # - run in the background so can have multiple sessions/visualizations going at the same time,
    #   although this does use more memory on the computer
    # - checking the exit status on background processes may be tricky
    if [ ! -f "${tstoolExe}" ]; then
      logWarning ""
      logWarning "${warnColor}TSTool program does not exist:${endColor}"
      logWarning "${warnColor}${tstoolExe}${endColor}"
      return 1
    fi

    doBackground="true"
    if [ "${doBackground}" = "true" ]; then
      ${tstoolExe} -- ${tstoolCommandFile} --space-replacement='___' TSID=="${tsid}" Description=="${tsDescription}" Scenario=="${selectedScenario}" &
      logInfo "${menuColor}Running TSTool in the background so that other tasks can be run.${endColor}"
      logInfo "${menuColor}TSTool messages may be written as it runs.${endColor}"
      logInfo "${menuColor}If necessary, press return to view the menu.${endColor}"
      # Give a little time to see the above.
      sleep 1
      # Can't get the return status here.
      return 0
    else
      logInfo "${menuColor}Running TSTool before continuing.${endColor}"
      ${tstoolExe} -- ${tstoolCommandFile} --space-replacement='___' TSID=="${tsid}" Description=="${tsDescription}" Scenario=="${selectedScenario}"
      if [ $? -ne 0 ]; then
        logWarning ""
        logWarning "${warnColor}Error running TSTool.${endColor}"
        return 1
      fi
    fi
  fi
  return 0
}

# Entry point into the script.

# Script location and name:
# - absolute location is typically only needed in development environment
# - name is used in some output, use the actual script in case file was renamed
scriptFolder=$(cd $(dirname "$0") && pwd)
scriptName=$(basename $0)
# The following works whether or not the script name has an extension.
scriptNameNoExt=$(echo ${scriptName} | cut -d '.' -f 1)
version="1.1.0 2021-08-31"

# Configure the echo command for colored output:
# - do this up front because results are used in messages
configureEcho

# Main folders.
testRepoFolder=$(dirname ${scriptFolder})
downloadsFolder="${testRepoFolder}/downloads"
downloadsDatasetsFolder="${downloadsFolder}/datasets"
downloadsExecutablesFolder="${downloadsFolder}/executables"
testFolder="${testRepoFolder}/test"
testDatasetsFolder="${testFolder}/datasets"
tstoolTemplatesFolder="${testRepoFolder}/tstool-templates"

logInfo "Important folders and files:"
logInfo "scriptFolder=${scriptFolder}"
logInfo "testRepoFolder=${testRepoFolder}"
logInfo "downloadsFolder=${downloadsFolder}"
logInfo "downloadsDatasetsFolder=${downloadsDatasetsFolder}"
logInfo "downloadsExecutablesFolder=${downloadsExecutablesFolder}"
logInfo "testfolder=${testFolder}"
logInfo "testDatasetsFolder=${testDatasetsFolder}"
logInfo "tstoolTemplatesFolder=${tstoolTemplatesFolder}"

# Controlling variables.
# Run mode for script ('batch' or 'interactive"):
# - will be set to 'batch' if command is detected
runMode="interactive"
debug="false"

# Check the Linux distribution so have operating system.
#checkLinuxDistro

# Parse the command line.
parseCommandLine $@

# Set the TSTool executable:
# - do this after parsing because need to handle --debug
# - the following will exit because TSTool is fundamental to testing
setTstoolExe
if [ -z "${tstoolExe}" ]; then
  # The above call should have handled everything but keep this code here for now.
  logError "${errorColor}Could not find TSTool executable 14+.  Exiting.${endColor}"
  logError "${errorColor}Need to install TSTool 14+.${endColor}"
fi

if [ "${command}" = "" ]; then
  # Command was not requested so run interactively.
  runInteractive
else
  # Command was requested on the command line so run it and exit.
  if [ "${command}" = "newdataset" ]; then
    newDataset batch
    exit $?
  else
    logWarning "${warnColor}Unknown command:  ${command}${endColor}"
    exit 1
  fi
fi

# Fall through.
exit 0
