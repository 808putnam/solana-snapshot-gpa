#!/bin/bash

# For reference: In case we make script run everything
# Clean up any previous runs
# rm -rf /solana/snapshot/*

# original implementation: to be removed
# SNAPSHOT=$1
# For reference: In case we make script run everything
# We capture the snapshot filename from snapshot-finder.py using a python print command
# SNAPSHOT=snapshot/`/solana/venv/bin/python3 qtrade-snapshot-finder.py`

# original implementation: to be removed
#                                      Given:    snapshot/snapshot-<slot>-<hash>.tar.zst
#  First 'cut' in command below will produce:  snapshot/snapshot-<slot>-<hash>
# Second 'cut' in command below will produce: <slot>
# SLOT=$(echo "snapshot/$SNAPSHOT" | cut -d. -f1 | cut -d- -f2)
# if [ -z "$SLOT" ]; then
#   echo "usage: create-qtrade-snapshot.sh snapshot-<slot>-<hash>.tar.zst"
#   exit 2
# fi


# Display help menu
usage() {
    echo ""
    echo "create-qtrade-snapshot.sh"
    echo "==============================================================================="
    echo  ""
    echo "Post processing of Solana snapshots."
    echo ""
    echo "-------------------------------------------------------------------------------"
    echo "Options"
    echo "-------------------------------------------------------------------------------"
    echo "--help              Displays help menu"
    echo ""
    echo "--snapshot_folder=<path>          Folder containing snapshot to process."
    echo "--snaphshot=<snapshot>            Snapshot to process."
    echo "--snapshot_path=<path>            Full path to snapshot."
    echo "--slot=<slot>                     Slot we are processing from."
    echo "--solana_snapshot_gpa_path=<path> Path to solana_snapshot_gpa binary."
    echo "--debug_exit_first_launch         Exit before first launch of solana-snapshot-gpa."
    echo "--debug_exit_second_launch        Exit before second launch of solana-snapshot-gpa."
    echo ""
    echo "-------------------------------------------------------------------------------"
    echo ""

    exit
}

# Parse input arguments
for i in "$@"
do
case $i in
    -h|--help)
    usage
    shift
    ;;
    --snapshot_folder=*)
    SNAPSHOT_FOLDER="${i#*=}"
    shift
    ;;
    --snapshot=*)
    SNAPSHOT="${i#*=}"
    shift
    ;;
    --snapshot_path=*)
    SNAPSHOT_PATH="${i#*=}"
    shift
    ;;
    --slot=*)
    SLOT="${i#*=}"
    shift
    ;;
    --solana_snapshot_gpa_path=*)
    SOLANA_SNAPSHOT_GPA_PATH="${i#*=}"
    shift
    ;;
    --debug_exit_first_launch=*)
    DEBUG_EXIT_FIRST_LAUNCH="${i#*=}"
    shift
    ;;
    --debug_exit_second_launch=*)
    DEBUG_EXIT_SECOND_LAUNCH="${i#*=}"
    shift
    ;;
    *)
    echo "Unknown option: $i"
    usage
    shift
    ;;
esac
done

if [[ "$SNAPSHOT_FOLDER" == "" ]]; then
    echo "--snapshot_folder must be set"
    usage
fi
if [[ "$SNAPSHOT" == "" ]]; then
    echo "--snapshot must be set"
    usage
fi
if [[ "$SNAPSHOT_PATH" == "" ]]; then
    echo "--snapshot_path must be set"
    usage
fi
if [[ "$SLOT" == "" ]]; then
    echo "--slot must be set"
    usage
fi
SLOT_PATH=$SNAPSHOT_FOLDER$SLOT
if [[ "SOLANA_SNAPSHOT_GPA_PATH" == "" ]]; then
    echo "--solana_snapshot_gpa_path must be set"
    usage
fi
if [ ! -e "$SOLANA_SNAPSHOT_GPA_PATH" ]; then
  echo "$SOLANA_SNAPSHOT_GPA_PATH does not exist"
  exit 1
fi
if [[ "$DEBUG_EXIT_FIRST_LAUNCH" == "" ]]; then
    echo "--debug_exit_first_launch must be set"
    usage
fi
if [[ "$DEBUG_EXIT_SECOND_LAUNCH" == "" ]]; then
    echo "--debug_exit_second_launch must be set"
    usage
fi

echo "Using the following values:"
echo "         snapshot folder: $SNAPSHOT_FOLDER"
echo "                snapshot: $SNAPSHOT"
echo "           snapshot path: $SNAPSHOT_PATH"
echo "                    slot: $SLOT"
echo "               slot path: $SLOT_PATH"
echo "solana-snapshot-gpa path: $SOLANA_SNAPSHOT_GPA_PATH"
echo " debug_exit_first_launch: $DEBUG_EXIT_FIRST_LAUNCH"
echo "debug_exit_second_launch: $DEBUG_EXIT_SECOND_LAUNCH"

# Original implementation: to be removed
# SNAPSHOT_GPA=./solana-snapshot-gpa
# if [ ! -e "$SNAPSHOT_GPA" ]; then
#   echo "$SNAPSHOT_GPA does not exist"
#   exit 1
# fi
# rm -irf $SLOT
# mkdir -p $SLOT

# Original implementation: to be removed
# ALL_DATA_ALL=$SLOT/all.data.all.csv
# POSITION_PUBKEY=$SLOT/position.pubkey.csv
# POSITION_BUNDLE_PUBKEY=$SLOT/position_bundle.pubkey.csv
# CLOSABLE_PUBKEY=$SLOT/closable.pubkey.csv
# CLOSABLE_DATA_ALL=$SLOT/closable.data.all.csv
# MERGED_DATA_ALL=$SLOT/merged.data.all.csv
# MERGED_DATA_LATEST=$SLOT/merged.data.latest.csv
# RESULT=$SLOT/whirlpool-snapshot-$SLOT.csv

ALL_DATA_ALL=$SLOT_PATH/all.data.all.csv
POSITION_PUBKEY=$SLOT_PATH/position.pubkey.csv
POSITION_BUNDLE_PUBKEY=$SLOT_PATH/position_bundle.pubkey.csv
CLOSABLE_PUBKEY=$SLOT_PATH/closable.pubkey.csv
CLOSABLE_DATA_ALL=$SLOT_PATH/closable.data.all.csv
MERGED_DATA_ALL=$SLOT_PATH/merged.data.all.csv
MERGED_DATA_LATEST=$SLOT_PATH/merged.data.latest.csv
RESULT=$SLOT_PATH/whirlpool-snapshot-$SLOT.csv

# Are we doing a debug run of the first launch of solana-snapshot-gpa?
if [[ "$DEBUG_EXIT_FIRST_LAUNCH" == "true" ]]; then
    echo "Exiting before first launch of solana-snapshot-gpa."
    exit
fi

# extract all whirlpool accounts (all versions)
$SOLANA_SNAPSHOT_GPA_PATH --owner=whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc $SNAPSHOT_PATH > $ALL_DATA_ALL

# extract all Position & PositionBundle account pubkeys
tail -n +2 $ALL_DATA_ALL | awk -F, '$3 == 216 {print $1}' | sort | uniq > $POSITION_PUBKEY
tail -n +2 $ALL_DATA_ALL | awk -F, '$3 == 136 {print $1}' | sort | uniq > $POSITION_BUNDLE_PUBKEY
cat $POSITION_PUBKEY $POSITION_BUNDLE_PUBKEY > $CLOSABLE_PUBKEY

# Are we doing a debug run of the second launch of solana-snapshot-gpa?
if [[ "$DEBUG_EXIT_SECOND_LAUNCH" == "true" ]]; then
    echo "Exiting before second launch of solana-snapshot-gpa."
    exit
fi

# extract all Position accounts (all versions)
$SOLANA_SNAPSHOT_GPA_PATH --pubkeyfile=$CLOSABLE_PUBKEY $SNAPSHOT > $CLOSABLE_DATA_ALL

# select latest write version
tail -n +2 $ALL_DATA_ALL > $MERGED_DATA_ALL
tail -n +2 $CLOSABLE_DATA_ALL >> $MERGED_DATA_ALL
cat $MERGED_DATA_ALL | sort -t, -k5,5nr | awk -F, '!dup[$1]++' > $MERGED_DATA_LATEST

# filter closed accounts
cat $MERGED_DATA_LATEST | awk -F, '$3 > 0 {print $0}' | sort -t, -k1 > $RESULT

# create gzipped file
gzip -c $RESULT > $RESULT.gz

