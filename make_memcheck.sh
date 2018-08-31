#!/bin/bash
#==========================================================================
#
# Description: This script builds the memcheck utility
#
# Usage: see function usage below
#
# Examples:
#     > ./make_memcheck.sh -h
#     > ./make_memcheck.sh -s theia -c intel -d /scratch4/home/USERNAME/MEMCHECK-20180401
#     > ./make_memcheck.sh -s cheyenne -c pgi -d /glade/p/work/USERNAME/MEMCHECK-20180401
#     > ./make_memcheck.sh -s macosx -c gnu -d /usr/local/MEMCHECK-20180401
#
#==========================================================================

# Define functions.

function fail    { [ -n "$1" ] && printf "\n%s\n" "$1"; exit 1; }

function usage   {
  echo "Usage: "
  echo "$THIS_FILE -s system -c compiler -d installdir | -h"
  echo "    Where: system     [required] can be : ${validsystems[@]}"
  echo "           compiler   [required] can be : ${validcompilers[@]}"
  echo "           installdir [required] is the installation destination (must exist)"
  exit 1
}

MEMCHECK_SRC_DIR=`pwd`

THIS_FILE=$(basename "$0" )

#--------------------------------------------------------------
# Define available options
#--------------------------------------------------------------
validsystems=( theia cheyenne macosx linux )
validcompilers=( intel pgi gnu )

#--------------------------------------------------------------
# Parse command line arguments
#--------------------------------------------------------------
while getopts :s:c:d:help opt; do
  case $opt in
    s) SYSTEM=$OPTARG ;;
    c) COMPILER=$OPTARG ;;
    d) MEMCHECK_DST_DIR=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Check if all mandatory arguments are provided
if [ -z $SYSTEM ] ; then usage; fi
if [ -z $COMPILER ] ; then usage; fi
if [ -z $MEMCHECK_DST_DIR ] ; then usage; fi

# Ensure value ($2) of variable ($1) is contained in list of validvalues ($3)
function checkvalid {
  if [ $# -lt 3 ]; then
    echo $FUNCNAME requires at least 3 arguments: stopping
    exit 1
  fi

  var_name=$1 && shift
  input_val=$1 && shift
  valid_vars=($@)

  for x in ${valid_vars[@]}; do
    if [ "$input_val" == "$x" ]; then
      echo "${var_name}=${input_val} is valid."
      return
    fi
  done
  echo "ERROR: ${var_name}=${input_val} is invalid. Valid values are: ${valid_vars[@]}"
  exit 1
}

checkvalid SYSTEM ${SYSTEM} ${validsystems[@]}
checkvalid COMPILER ${COMPILER} ${validcompilers[@]}

if [ -d ${MEMCHECK_DST_DIR} ]; then
  echo "Destination directory ${MEMCHECK_DST_DIR} exists."
else
  echo "ERROR: Destination directory ${MEMCHECK_DST_DIR} does not exist."
  exit 1
fi

#--------------------------------------------------------------
# Get the build root directory
#--------------------------------------------------------------
export BUILD_DIR="${MEMCHECK_SRC_DIR}/exec_${SYSTEM}.${COMPILER}"
echo
echo "Building memcheck utility in ${BUILD_DIR} ..."
echo

#--------------------------------------------------------------
# Copy library source to BUILD_DIR and build
#--------------------------------------------------------------
rm -fr ${BUILD_DIR}
mkdir ${BUILD_DIR}
cp -av Makefile no_ccpp_memory.* memcheck_mod.F90 ${BUILD_DIR}

#--------------------------------------------------------------
# Copy appropriate macros.make file
#--------------------------------------------------------------
MACROS_FILE=${BUILD_DIR}/macros.make
cp -v macros.make.${SYSTEM}.${COMPILER} ${MACROS_FILE}

#--------------------------------------------------------------
# Build project
#--------------------------------------------------------------
cd ${BUILD_DIR}
make || fail "An error occurred building the memcheck utility"

#--------------------------------------------------------------
# Install to MEMCHECK_DST_DIR
#--------------------------------------------------------------
echo
echo "Installing to ${MEMCHECK_DST_DIR} ..."
echo
rm -fr ${MEMCHECK_DST_DIR}/*
mkdir ${MEMCHECK_DST_DIR}/lib
mkdir ${MEMCHECK_DST_DIR}/include
cp -av ${BUILD_DIR}/include/* ${MEMCHECK_DST_DIR}/include/
cp -av ${BUILD_DIR}/lib/* ${MEMCHECK_DST_DIR}/lib/

echo
echo "To build FV3, set environment variable MEMCHECK_DIR to ${MEMCHECK_DST_DIR}"
echo
