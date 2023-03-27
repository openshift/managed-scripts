#!/bin/sh
# This is a Bash script that defines a logging system with different levels of verbosity. The script provides functions for logging messages at different levels such as info, success, error, warning, and debug. The script determines whether to write those messages to STDOUT or to a log file based on the value of two environment variables, LOG_LEVEL_STDOUT and LOG_LEVEL_LOG.

# If you define $LOG_PATH in your script, then the logs will be written to that file. By default, all log levels will be written to both STDOUT and LOG_PATH. However, you can set LOG_LEVEL_STDOUT and LOG_LEVEL_LOG to control which log levels will be written to STDOUT and LOG_PATH.

# The script also sets up colorized output for interactive terminals, and provides a function to scrub that output of control characters when writing to non-interactive outputs.

# To use this script, you would source it in your own script and then call the logging functions as needed, passing in the message you want to log and the level of verbosity you want it to have. The script provides global variables that users may wish to reference such as SCRIPT_ARGS and SCRIPT_NAME.

# LOG_LEVEL_STDOUT - Define to determine above which level goes to STDOUT.
# By default, all log levels will be written to STDOUT.
LOG_LEVEL_STDOUT="INFO"

# LOG_LEVEL_LOG - Define to determine which level goes to LOG_PATH.
# By default all log levels will be written to LOG_PATH.
LOG_LEVEL_LOG="INFO"

# Useful global variables that users may wish to reference
# shellcheck disable=SC2034
# shellcheck disable=SC3030
# shellcheck disable=SC2039
SCRIPT_ARGS=("$@") 
# shellcheck disable=SC2034
SCRIPT_NAME="${0##*/}"

# Determines if we print colors or not
if [ "$(tty -s)" ]; then
  readonly INTERACTIVE_MODE="off"
else
  readonly INTERACTIVE_MODE="on"
fi

#--------------------------------------------------------------------------------------------------
# Begin Logging Section
if [ "${INTERACTIVE_MODE}" = "off" ]; then
  # Then we don't care about log colors
  LOG_DEFAULT_COLOR=""
  LOG_ERROR_COLOR=""
  LOG_INFO_COLOR=""
  LOG_SUCCESS_COLOR=""
  LOG_WARN_COLOR=""
  LOG_DEBUG_COLOR=""
else
  LOG_DEFAULT_COLOR=$(tput sgr0)
  LOG_ERROR_COLOR=$(tput setaf 1)
  LOG_INFO_COLOR=$(tput sgr0)
  LOG_SUCCESS_COLOR=$(tput setaf 2)
  LOG_WARN_COLOR=$(tput setaf 3)
  LOG_DEBUG_COLOR=$(tput setaf 4)
fi

# This function scrubs the output of any control characters used in colorized output
# It's designed to be piped through with text that needs scrubbing.  The scrubbed
# text will come out the other side!
prepare_log_for_nonterminal() {
  # Essentially this strips all the control characters for log colors
  sed "s/[[:cntrl:]]\[[0-9;]*m//g"
}

log() {
 # shellcheck disable=SC3043
  local log_text="$1"
  # shellcheck disable=SC3043
  local log_level="${2:-INFO}"
  # shellcheck disable=SC3043
  local log_color="${3:-${LOG_INFO_COLOR}}"

  # Levels for comparing against LOG_LEVEL_STDOUT and LOG_LEVEL_LOG
  # shellcheck disable=SC2034
  # shellcheck disable=SC3043
  local LOG_LEVEL_DEBUG=0
  # shellcheck disable=SC2034
  # shellcheck disable=SC3043
  local LOG_LEVEL_INFO=1
  # shellcheck disable=SC2034
  # shellcheck disable=SC3043
  local LOG_LEVEL_SUCCESS=2
  # shellcheck disable=SC3043
  # shellcheck disable=SC2034
  local LOG_LEVEL_WARNING=3
  # shellcheck disable=SC2034
  # shellcheck disable=SC3043
  local LOG_LEVEL_ERROR=4
  # shellcheck disable=SC2034
  # shellcheck disable=SC3043

  # Validate LOG_LEVEL_STDOUT and LOG_LEVEL_LOG since they'll be eval-ed.
  case $LOG_LEVEL_STDOUT in
    DEBUG|INFO|SUCCESS|WARNING|ERROR)
      ;;
    *)
      LOG_LEVEL_STDOUT=INFO
      ;;
  esac
  case $LOG_LEVEL_LOG in
    DEBUG|INFO|SUCCESS|WARNING|ERROR)
      ;;
    *)
      LOG_LEVEL_LOG=INFO
      ;;
  esac

  # Check LOG_LEVEL_STDOUT to see if this level of entry goes to STDOUT.
  eval log_level_int="\$LOG_LEVEL_${log_level}"
  eval log_level_stdout="\$LOG_LEVEL_${LOG_LEVEL_STDOUT}"
   # shellcheck disable=SC2154
  if [ "$log_level_stdout" -le "$log_level_int" ]; then
    # STDOUT
    printf "%s[%s] [%s] %s %s\n" "$log_color" "$(date +"%Y-%m-%d %H:%M:%S %Z")" "$log_level" "$log_text" "$LOG_DEFAULT_COLOR"
  fi
  eval log_level_log="\$LOG_LEVEL_${LOG_LEVEL_LOG}"
  # Check LOG_LEVEL_LOG to see if this level of entry goes to LOG_PATH
  # shellcheck disable=SC2154
  if [ "$log_level_log" -le "$log_level_int" ]; then
    if [ -n "$LOG_PATH"  ]; then
            printf "[%s] [%s] %s\n" "$(date +"%Y-%m-%d %H:%M:%S %Z")" "$log_level" "$log_text" >> "$LOG_PATH"
        fi
    fi

    return 0;
}

log_info()      { log "$@"; }
log_success()   { log "$1" "SUCCESS" "${LOG_SUCCESS_COLOR}"; }
log_error()     { log "$1" "ERROR" "${LOG_ERROR_COLOR}"; }
log_warning()   { log "$1" "WARNING" "${LOG_WARN_COLOR}"; }
log_debug()     { log "$1" "DEBUG" "${LOG_DEBUG_COLOR}"; }