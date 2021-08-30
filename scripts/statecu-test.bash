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
  # Brute force parse since can be 0, 1, or 2 parameters.
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
      ds=$1
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${1}"
    else
      ds=$2
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
      ds=$1
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${1}"
    else
      ds=$2
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
      ds=${2}
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
      ds=$1
    fi
  fi
  if [ $# -gt 1 ]; then
    if [ "${2}" = "raw" -o "${2}" = "numbered" -o "${2}" = "indented" ]; then
      format="${1}"
    else
      ds=$2
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
  local statecuFolder testVariantFolder

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

  # Try case where StateCU folder exists in the top of the dataset folder.
  statecuFolder="${testVariantFolder}/StateCU"
  if [ -d "${statecuFolder}" ]; then
    logInfo ""
    logInfo "StateCU folder is in top folder of dataset:"
    logInfo "  ${statecuFolder}"
    echo "${statecuFolder}"
    return 0
  else
    # Try the subfolder in the datset:
    # - the subfolder name has typically matched the zip file name but this is not guaranteed
    # - could do a "find" but want to ensure some consistency
    statecuFolder="${testVariantFolder}/$(basename ${testDatasetFolder})/StateCU"
    if [ -d "${statecuFolder}" ]; then
      logInfo ""
      logInfo "StateCU folder is in first sub-folder of dataset:"
      logInfo "  ${statecuFolder}"
      echo "${statecuFolder}"
      return 0
    else
      logWarning
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
          logInfo "Copying dataset files:"
          logInfo "  from: ${datasetFromFolder}"
          logInfo "    to: ${testVariantFolder}"
          cp -r ${datasetFromFolder} ${testVariantFolder}
          if [ $? -eq 0 ]; then
             logInfo "Success copying dataset files."
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
    logText "${menuColor}lsc${endColor}omp"
    logText ""
    logText "List test dataset variant comparisons."
    logText "Comparisons are saved in a folder named with dataset and executable names."
  elif [[ "${command}" = "c"* ]]; then
    logText "${menuColor}c${endColor}omp"
    logText ""
    logText "Compare two dataset test variants, for example baseline and current version."
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
        logInfo "Successfully deleted dataset."
      else
        logWarning "Error deleting dataset."
        logWarning "Files may be opened in software or command line session may be in folder."
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
    logInfo "There are no test dataset variants.  Need to create a test dataset with executable variant."
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
        logInfo "Successfully deleted dataset variant."
      else
        logWarning "Error deleting dataset variant."
        logWarning "Files may be opened in software or command line session may be in folder."
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
    ${echo2} "Compare.....${menuColor}lsc${endColor}omp                 - list a test dataset comparison"
    ${echo2} "            ${menuColor}newc${endColor}omp                - create a comparison for 2 dataset test variants"
    ${echo2} "            ${menuColor}runc${endColor}omp                - run a comparison using TSTool"
    ${echo2} "            ${menuColor}v${endColor}iewomp                - view comparison of specific location "
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
      listTestDatasetVariantsFromMenu ${dataset}
    # ======================
    elif [[ "${answer}" = "newt"* ]]; then
      # Create a new test dataset:
      newTestDataset
    elif [[ "${answer}" = "newv"* ]]; then
      # Create a new test dataset vaiant:
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

# Entry point into the script.

# Script location and name:
# - absolute location is typically only needed in development environment
# - name is used in some output, use the actual script in case file was renamed
scriptFolder=$(cd $(dirname "$0") && pwd)
scriptName=$(basename $0)
# The following works whether or not the script name has an extension.
scriptNameNoExt=$(echo ${scriptName} | cut -d '.' -f 1)
version="1.0.0 2021-08-14"

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

logInfo "Important folders:"
logInfo "scriptFolder=${scriptFolder}"
logInfo "testRepoFolder=${testRepoFolder}"
logInfo "downloadsFolder=${downloadsFolder}"
logInfo "downloadsDatasetsFolder=${downloadsDatasetsFolder}"
logInfo "downloadsExecutablesFolder=${downloadsExecutablesFolder}"
logInfo "testfolder=${testFolder}"
logInfo "testDatasetsFolder=${testDatasetsFolder}"

# Controlling variables.
# Run mode for script ('batch' or 'interactive"):
# - will be set to 'batch' if command is detected
runMode="interactive"
debug="false"

# Check the Linux distribution so have operating system.
#checkLinuxDistro

# Parse the command line.
parseCommandLine $@

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
