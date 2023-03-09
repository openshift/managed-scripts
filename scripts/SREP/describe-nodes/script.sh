#!/bin/bash
#
# Commnad: describe-nodes
# Description: Describes the nodes in a cluster by calling `oc decribe nodes`
#              This is useful to be run as a backplane script where more more authorisation can be provided when compared to the standard bacplane cli access. 

# Exit on error
set -e
# Treat unset variables as error
set -u
# Print expanded commands with arguments before executing them
# set -x
# Set the return value in a set of pipes to the rightmost failed command
set -o pipefail

## Display error and end
function error-out() {
  echo "\
usage: describe-nodes [--all | --master | --infra | --worker | --nodes <node>,<node>,...]
  -a, --all             : Describe all nodes in the cluster
  -m, --master          : Describe the master nodes in the cluster
  -i, --infra           : Describe the infra nodes in the cluster
  -w, --worker          : Describe the worker nodes in the cluster
  -l, --selector        : A Label selector to pass to oc describe nodes
  -n, --nodes, --node   : Specify the nodes to describe in the cluster separated by a ',' with no spaces
  -d, --debug           : Enable debugging
  -h, --help            : Print this help

Argument precedence as only one mode can be used at a time: (the first available is used)
  --help
  --nodes
  --selector
  --all
  --master and|or --worker --and|or infra
  The --debug argument can be used at anytime"
  if [ ! -n "${1-}" ]
  then 
    exit 0
  else
    echo
    echo "$0: ERROR: $1"  
    exit 1
  fi
}

# Add argument to the nodes variable
function add2nodes() {
  nodes="$nodes${1}"
}

# List nodes that match a specific selector past in as $1
function list-selector() {
    oc get nodes -l "${1}" --no-headers -o custom-columns=":metadata.name" | tr "\n" ","
}

# Initialise variables usesd while parsing commandline arguments
all=flase
master=flase
infra=flase
worker=flase
nodes=""
selector=""

# Parse command line arguments
if [ -z ${SCRIPT_PARAMETERS+x} ]
then
  error-out "The 'SCRIPT_PARAMETERS' argument has not been provided: via Bacplane script parameter; Or via export if running on the cmdline"
fi
# echo "${SCRIPT_PARAMETERS}"
ARG_ARRAY=( ${SCRIPT_PARAMETERS} )
# echo "ARG_ARRAY: ${ARG_ARRAY}"
while [[ ${#ARG_ARRAY[@]} -gt 0 ]]
do
  # echo "in while"
  case ${ARG_ARRAY[0]} in
    -h|--help)
      error-out
      ;;
    -a|--all)
      all=true
      ARG_ARRAY=("${ARG_ARRAY[@]:1}")  # shift past argument
      ;;
    -m|--master)
      master=true
      ARG_ARRAY=("${ARG_ARRAY[@]:1}")  # shift past argument
      ;;
    -i|--infra)
      infra=true
      ARG_ARRAY=("${ARG_ARRAY[@]:1}")  # shift past argument
      ;;
    -w|--worker)
      worker=true
      ARG_ARRAY=("${ARG_ARRAY[@]:1}")  # shift past argument
      ;;
    -d|--debug)
      set -x  # Print expanded commands with arguments
      ARG_ARRAY=("${ARG_ARRAY[@]:1}")  # shift past argument
      ;;
    -n|--node|--nodes)
      if [ ! -z "$nodes" ]
      then
        error-out "Only 1 '--nodes' argument can be provided"
      fi
      # Check for unset or empty arguments and values that look like a flag/switch
      if [ ${#ARG_ARRAY[@]} -le 1 ] \
        || [ -z ${ARG_ARRAY[1]} ] \
        || [[ ${ARG_ARRAY[1]} =~ ^-.* ]]
      then
        error-out "The --nodes requires a list of nodes"
      fi
      # Check for ilegal characters in the list of nodes
      badchars="$(echo ${ARG_ARRAY[1]} | tr -d '[:alnum:]' | tr -d '-' | tr -d '.' | tr -d ',')"
      if [ ! -z ${badchars} ]
      then  
        error-out "'--nodes' can only contain '.|-|,|<alphanumric>' characters.  These characters '${badchars}' are ileagal"
      fi
      nodes=${ARG_ARRAY[1]}
      ARG_ARRAY=("${ARG_ARRAY[@]:2}")  # shift past argument and value
      ;;
    -l|--selector)
      if [ ! -z "$selector" ]
      then
        error-out "Only 1 '--selector' argument can be provided"
      fi
      # Check for unset or empty arguments and values that look like a flag/switch
      if [ ${#ARG_ARRAY[@]} -le 1 ] \
        || [ -z ${ARG_ARRAY[1]} ] \
        || [[ ${ARG_ARRAY[1]} =~ ^-.* ]]
      then
        error-out "'--selector' must contain a node selector"
      fi
      badchars="$(echo ${ARG_ARRAY[1]} | tr -d '[:alnum:]' | tr -d '-' | tr -d '.'  | tr -d '/'  \
          | tr -d ',' | tr -d ':' | tr -d ' ' | tr -d '(' | tr -d ')' | tr -d '!' | tr -d '=')"
      if [ ! -z ${badchars} ]
      then
        error-out "--selector ilegal caharcters in selector.  These characters '${badchars}' are ileagal"
      fi
      selector=${ARG_ARRAY[1]}
      ARG_ARRAY=("${ARG_ARRAY[@]:2}")  # shift past argument and value
      ;;
    -*|--*)
      error-out "Unknown option ${ARG_ARRAY[0]}"
      ;;
    *)
      error-out "Unknown argument"
      ;;
  esac
done

# If --nodes is supplied use that and ignore all other arguments
# else if --selector is supplied use that ignore the otheres arguments
# else if --all is supplied use that ignore the otheres arguments
# else if any of the --master or --infra or --worker arguments are supplied use them all
if [ ! -z "$nodes" ]
then
  
elif [ ! -z "$selector" ]
then
  nodes=$(list-selector $selector)
elif [ "$all" = true ]
then
  add2nodes $(list-selector "node-role.kubernetes.io/master")
  add2nodes $(list-selector "node-role.kubernetes.io=infra")
  add2nodes $(list-selector "node-role.kubernetes.io!=infra,node-role.kubernetes.io/worker")
else
  if [ "$master" = true ]
  then
    add2nodes $(list-selector "node-role.kubernetes.io/master")
  fi
  if [ "$infra" = true ]
  then
    add2nodes $(list-selector "node-role.kubernetes.io=infra")
  fi
  if [ "$worker" = true ]
  then
    add2nodes $(list-selector "node-role.kubernetes.io!=infra,node-role.kubernetes.io/worker")
  fi
fi

# If he nodes variable is empty, it means the no arguments were supplied on the command line
# Or the selector(s) did not pick any nodes.  This is an error
if [ ! -n "$nodes" ] 
then
  error-out "No nodes selected"
fi

nodes=$(echo ${nodes} | tr "," " ")
oc describe nodes $nodes
exit 0