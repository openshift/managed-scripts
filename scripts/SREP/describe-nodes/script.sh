#!/bin/bash
#
# Replace a master machine.
# Input:
#  (Env) MACHINE
#    name of the machine resource in cluster

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
  echo "$0: $1"
  echo "\
usage: describe-nodes [--all | --master | --infra | --worker | --nodes <node>,<node>,...]
  --all      : Describe all nodes in the cluster
  --master   : Describe the master nodes in the cluster
  --infra    : Describe the infra nodes in the cluster
  --worker   : Describe the worker nodes in the cluster
  --selector : A Label selector to pass to oc describe nodes
  --nodes    : Describe the listed nodes in the cluster.  The list comprises of the node name seperated by a comma with no spaces  ; 
  --help     : Print this help

Argument precedence as only one mode can be used at a time: (the first available is used)
  --nodes
  --selector
  --all
  --master and|or --worker --and|or infra"
  exit 1
}

function add2nodes() {
  nodes="$nodes${1}"
}

function list-selector() {
    oc get nodes -l ${1} | tail -n +2 | cut -d " " -f 1 | tr "\n" ","
}

all=flase
master=flase
infra=flase
worker=flase
nodes=""
selector=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      error-out "Help!"
      ;;
    --all)
      all=true
      shift # past argument
      ;;
    --master)
      master=true
      shift # past argument
      ;;
    --infra)
      infra=true
      shift # past argument
      ;;
    --worker)
      worker=1
      shift # past argument
      ;;
    --nodes)
      if [ ! -z "$nodes" ]
      then
        error-out "Only 1 '--nodes' argument can be provided"
      fi
      nodes=${2}
      shift # past argument
      shift # past value
      ;;
    --selector)
      if [ ! -z "$selector" ]
      then
        error-out "Only 1 '--selector' argument can be provided"
      fi
      selector=${2}
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      error-out "Unknown option $1"
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
  break
elif [ ! -z "$selector" ]
then
  nodes = list-selector ${selector}
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

if [ ! -n "$nodes" ] 
then
  error-out "No nodes selected"
fi

nodes=$(echo ${nodes} | tr "," " ")
echo oc describe nodes $nodes
exit 0