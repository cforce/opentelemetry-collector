#!/usr/bin/env bash
#
# Copyright The OpenTelemetry Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script is used to create API state snapshots used to validate releases are not breaking backwards compatibility.

usage() {
  echo "Usage: $0"
  echo
  echo "-d  Dry-run mode. No project files will not be modified. Default: 'false'"
  echo "-p  Package to generate API state snapshot of. Default: ''"
  echo "-o  Output directory where state will be written to. Default: './internal/data/apidiff'"
  exit 1
}

dry_run=false
package=""
output_dir="./internal/data/apidiff"
apidiff_cmd="$(git rev-parse --show-toplevel)/.tools/apidiff"


while getopts "dp:o:" o; do
    case "${o}" in
        d)
            dry_run=true
            ;;
        p)
            package=$OPTARG
            ;;
        o)
            output_dir=$OPTARG
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$package" ]; then
  usage
fi

set -ex

# Create temp dir for generated files.
tmp_dir=$(mktemp -d -t apidiff)
clean_up() {
    ARG=$?
    if [ $dry_run = true ]; then
      echo "Dry-run complete. Generated files can be found in $tmp_dir"
    else
      rm -rf "$tmp_dir"
    fi
    exit $ARG
}
trap clean_up EXIT

mkdir -p "$tmp_dir/$package"

${apidiff_cmd} -w "$tmp_dir"/"$package"/apidiff.state "$package"

# Copy files if not in dry-run mode.
if [ $dry_run = false ]; then
  mkdir -p "$output_dir/$package" && \
  cp "$tmp_dir/$package/apidiff.state" \
     "$output_dir/$package"
fi
