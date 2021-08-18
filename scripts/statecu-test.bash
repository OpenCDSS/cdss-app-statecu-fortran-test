#!/bin/bash
#
# statecu-test - utility to help manage StateCU tests in the development environment
#
# The script provides features to:
# - initialize folders for tests
# - run StateCU
# - run TSTool

# Supporting functions, alphabetized...

# List the download datasets.
listDownloadDatasets() {
  logText ""
  logText "Downloaded datasets in:  ${downloadsDatasetsFolder}"
  'ls' -1 ${downloadsDatasetsFolder} | grep -v README.md | awk '{printf("  %s\n", $0)}'
}

# List the download executables.
listDownloadExecutables() {
  logText ""
  logText "Downloaded executables in:  ${downloadsExecutablesFolder}"
  'ls' -1 ${downloadsExecutablesFolder} | grep -v README.md | awk '{printf("  %s\n", $0)}'
}

# List the test datasets.
# - first argument is the optional dataset
listTestDatasets() {
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

# List the datasets:
# - if the first parameter is a dataset, list it's contents
listDatasets() {
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

# Helper function to list datasets with line numbers.
# The number can then be entered to select a dataset.
listDatasetsWithNumbers() {
  'ls' -1 ${testDatasetsFolder} | awk '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       printf("%d - %s\n", line, $0)
     }'
}

# Helper function to list executables with line numbers.
# The number can then be entered to select an executable.
listExecutablesWithNumbers() {
  'ls' -1 ${downloadsExecutablesFolder} | awk '
     BEGIN {
       line = 0
     }
     {
       line = line + 1
       printf("%d - %s\n", line, $0)
     }'
}

# Create a new test datasets:
# - prompt for the dataset
# - prompt for the executable
newTestDataset() {
  local selectedDataset selectedDatasetNumber
  local selectedExecutable selectedExecutableNumber

  logText ""
  logText "Create a new test dataset:"
  logText " - select a dataset and executable"
  logText " - the dataset is copied to a test folder with name matching the executable"
  logText " - the executable is copied into the StateCU folder"
  logText " - the model can then be run"
  logText ""
  while [ "1" = "1" ]; do
    listDatasetsWithNumbers
    read -p "Select a dataset (#/q/ ): " selectedDataset
    if [ "${selectedDatasetNumber}" = "q" -o "${selectedDatasetNumber}" = "Q" ]; then
      exit 0
    elif [ -z "${selectedDatasetNumber}" ]; then
      break
    else
      # Have a dataset.  Next pick the executable.
      selectedDataset=$('ls' -1 | head -${selectedDatasetNumber} | tail -1 | cut -d '-' -f 2 | tr -d ' ')
      logText "Selected dataset: ${selectedDataset}"
      testDatasetFolder="${testDatasetsFolder}/${selectedDataset}"
      if [ ! -d "${testDatasetFolder}" ]; then
        logWarning ""
        logWarning "The main test dataset folder does not exist:"
        logWarning "  ${testDatasetFolder}"
        logWarning "Run the downloads command file to install the original dataset."
        return 1
      fi
      while [ "1" = "1" ]; do
        listExecutablesWithNumbers
        read -p "Select an executable (#/q/ ): " selectedExecutable
        if [ "${selectedExecutableNumber}" = "q" -o "${selectedExecutableNumber}" = "Q" ]; then
          exit 0
        elif [ -z "${selectedExecutableNumber}" ]; then
          # Just return rather than chaining a break in the outside loop.
          return 0
        else
          # Have an executable.  Continue with creating the test dataset.
          selectedExecutable=$('ls' -1 | head -${selectedExecutableNumber} | tail -1 | cut -d '-' -f 2 | tr -d ' ')
          logText "Selected executable: ${selectedExecutable}"
          # TODO smalers 2021-08-17 need to make sure this works on Linux where extensions will not be used.
          selectedExecutableNoExt=${selectedExecutable%.*}
          testVariantFolder="${testDatasetFolder}/${selectedExecutableNoExt}"
          if [ -d "${testVariantFolder}" ]; then
            logWarning ""
            logWarning "Dataset test exists:"
            logWarning "  ${testVariantFolder}:"
            read -p "Replace (Y/n/q)? " answer
            if [ "${answer}" = "q" -o "${answer}" = "Q" ]; then
              exit 0
            elif [ "${answer}" = "y" -o "${answer}" = "Y" ]; then
              rm -rf "${testVariantFolder}"
              if [ $? -ne 0 ]; then
                logWarning "${warnColor}Unable to remove folder:  ${testVariantFolder}${endColor}"
                logWarning "${warnColor}File(s) may be open in software.${endColor}"
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
          LogInfo ""
          LogInfo "Copying dataset files:"
          LogInfo "  from: ${datasetFromFolder}"
          LogInfo "    to: ${testVariantFolder}"
          cp -r ${datsetFromFolder} ${testVariantFolder}
          if [ $? -eq 0 ]; then
             logInfo "Success copying dataset files."
          else
             logWarning "${warnColor}Error copying dataset - check script code.${endColor}"
             return 1
          fi
          # Copy the executable.
          # First determine the StateCU folder.
          # May be in top level of the dataset or one down due to zip file contents.
          statecuFolder="${testVariantFolder}/StateCU"
          if [ -d "${statecuFolder}" ]; then
            logInfo "StateCU folder is in top folder of dataset:"
            logInfo "  ${statecuFolder}"
          else
            # Try the subfolder in the datset:
            # - the subfolder name has typically matched the zip file name but this is not guaranteed
            # - could do a "find" but want to ensure some consistency
            statecuFolder="${testVariantFolder}/$(basename ${testDatasetFolder})/StateCU"
            if [ -d "${statecuFolder}" ]; then
              logInfo "StateCU folder is in first sub-folder of dataset:"
              logInfo "  ${statecuFolder}"
            else
              logWarning "Unable to determine StateCU folder in dataset:"
              logWarning "  ${testVariantFolder}"
              logWarning "Need to check script code."
              return 1
            fi
          fi
          executableFrom=${downloadsExecutablesFolder}/${selectedExecutable}
          LogInfo ""
          LogInfo "Copying executable:"
          LogInfo "  from: ${executableFrom}"
          LogInfo "    to: ${statecuFolder}"
          if [ $? -eq 0 ]; then
             logInfo "Success copying executable file."
          else
             logWarning "${warnColor}Error copying executable - check script code.${endColor}"
             return 1
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

# Print help for a command.
printHelp() {
  local command

  command=$1

  # List in order of the interactive menus.
  logText ""
  # ==========================
  # Downloads
  # ==========================
  if [[ "${command}" = "lsdd"* ]]; then
    logText "${menuColor}lsdd${endColor}s"
    logText ""
    logText "List datasets in the downloads folder."
    logText "The datasets form the basis of tests."
  elif [[ "${command}" = "lsde"* ]]; then
    logText "${menuColor}lsde${endColor}xe"
    logText ""
    logText "List executables in the downloads folder."
    logText "These are used for test dataset variants."
  # ==========================
  # Test Datasets
  # ==========================
  elif [[ "${command}" = "lst"* ]]; then
    logText "${menuColor}lst${endColor}ds [dataset]"
    logText ""
    logText "With no argument, list test datasets, which match download dataset names."
    logText "With an argument, list test dataset variants for the dataset."
    logText "The 'datset' can contain wildcards (e.g., *cm*)."
    logText "Test dataset variants match StateCU executable names."
  elif [[ "${command}" = "new"* ]]; then
    logText "${menuColor}new${endColor}test [dataset]"
    logText ""
    logText "Create a new test dataset variant."
    logText "Prompts are provided for dataset and executable."
    logText "Test dataset variants match StateCU executable names."
  elif [[ "${command}" = "rmt"* ]]; then
    logText "${menuColor}rmt${endColor}est"
    logText ""
    logText "Remove new test dataset variant."
    logText "A prompt is provided to confirm the removal."
  # ==========================
  # StateCU
  # ==========================
  elif [[ "${command}" = "ru"* ]]; then
    logText "${menuColor}ru${endColor}n"
    logText ""
    logText "Run StateCU on a test dataset."
  # ==========================
  # Compare
  # ==========================
  elif [[ "${command}" = "lsc"* ]]; then
    logText "${menuColor}lsc${endColor}omp"
    logText ""
    logText "Remove new test dataset variant."
    logText "A prompt is provided to confirm the removal."
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
    logText "${warnColor}Can' print help.${endColor}"
  else
    logText "${warnColor}Specify a command after 'h' to print command help.${endColor}"
  fi
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
    ${echo2} "Downloads.....${menuColor}lsdd${endColor}s               - list downloaded datasets"
    ${echo2} "              ${menuColor}lsde${endColor}xe              - list downloaded executables"
    ${echo2} ""
    ${echo2} "Test..........${menuColor}lst${endColor}ds [dataset]     - list datasets (or dataset tests)"
    ${echo2} "Datasets      ${menuColor}new${endColor}test             - create a test variant for a dataset"
    ${echo2} "              ${menuColor}rmt${endColor}est              - remove test dataset folder"
    ${echo2} ""
    ${echo2} "StateCU.......${menuColor}ru${endColor}n                 - run a test dataset"
    ${echo2} ""
    ${echo2} "Compare.......${menuColor}lsc${endColor}omp              - list a test dataset comparison"
    ${echo2} "              ${menuColor}c${endColor}omp                - compare test dataset output"
    ${echo2} "              ${menuColor}rmc${endColor}omp              - remove a comparison"
    ${echo2} "${lineEquals}"
    ${echo2} "              ${menuColor}q${endColor}uit"
    ${echo2} "              ${menuColor}h${endColor}elp [command]"
    ${echo2} ""
    read -p "Enter menu item: " answer
    # -------- Downloads ----------
    if [[ "${answer}" = "lsdd"* ]]; then
      listDownloadDatasets
    elif [[ "${answer}" = "lsde"* ]]; then
      listDownloadExecutables
    # -------- Dataset tests ------
    elif [[ "${answer}" = "lst"* ]]; then
      # List the datasets or the contents of a dataset's folder.
      answerWordCount=$(echo ${answer} | wc -w)
      if [ "${answerWordCount}" -eq 2 ]; then
        # Menu item followed by dataset name.
        dataset=$(echo ${answer} | cut -d ' ' -f 2)
      else
        # Assume just menu item so default database.
        dataset=""
      fi
      listTestDatasets ${dataset}
    elif [[ "${answer}" = "n"* ]]; then
      # Create a new dataset test:
      # - the test variant will match an executable name
      newTestDataset
    # -------- StateCU -----------
    elif [[ "${answer}" = "runds"* ]]; then
      # Run a dataset in the testing framework:
      # - for example dataset is 'cm2015'
      answerWordCount=$(echo ${answer} | wc -w)
      if [ "${answerWordCount}" -eq 2 ]; then
        # Menu item followed by dataset name.
        dataset=$(echo ${answer} | cut -d ' ' -f 2)
      else
        # Assume just menu item so default database.
        dataset=""
      fi
      runDataset ${dataset}
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
      echo "Don't know how to handle option:  ${answer}"
    fi
  done
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
