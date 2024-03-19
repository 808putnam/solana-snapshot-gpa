#!/bin/bash

# For reference: In case we make script run everything
# Clean up any previous runs
# rm -rf /solana/snapshot/*

SNAPSHOT=$1
# For reference: In case we make script run everything
# We capture the snapshot filename from snapshot-finder.py using a python print command
# SNAPSHOT=snapshot/`/solana/venv/bin/python3 qtrade-snapshot-finder.py`

#                                      Given:    snapshot/snapshot-<slot>-<hash>.tar.zst
#  First 'cut' in command below will produce:  snapshot/snapshot-<slot>-<hash>
# Second 'cut' in command below will produce: <slot>
SLOT=$(echo "snapshot/$SNAPSHOT" | cut -d. -f1 | cut -d- -f2)
if [ -z "$SLOT" ]; then
  echo "usage: create-qtrade-snapshot.sh snapshot-<slot>-<hash>.tar.zst"
  exit 2
fi

echo "Using the following snapshot and slot:"
echo "Snapshot: $SNAPSHOT"
echo "    Slot: $SLOT"

SNAPSHOT_GPA=./solana-snapshot-gpa
if [ ! -e "$SNAPSHOT_GPA" ]; then
  echo "$SNAPSHOT_GPA does not exist"
  exit 1
fi

rm -irf $SLOT
mkdir -p $SLOT

ALL_DATA_ALL=$SLOT/all.data.all.csv
POSITION_PUBKEY=$SLOT/position.pubkey.csv
POSITION_BUNDLE_PUBKEY=$SLOT/position_bundle.pubkey.csv
CLOSABLE_PUBKEY=$SLOT/closable.pubkey.csv
CLOSABLE_DATA_ALL=$SLOT/closable.data.all.csv
MERGED_DATA_ALL=$SLOT/merged.data.all.csv
MERGED_DATA_LATEST=$SLOT/merged.data.latest.csv
RESULT=$SLOT/whirlpool-snapshot-$SLOT.csv

# extract all whirlpool accounts (all versions)
$SNAPSHOT_GPA --owner=whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc $SNAPSHOT > $ALL_DATA_ALL

# extract all Position & PositionBundle account pubkeys
tail -n +2 $ALL_DATA_ALL | awk -F, '$3 == 216 {print $1}' | sort | uniq > $POSITION_PUBKEY
tail -n +2 $ALL_DATA_ALL | awk -F, '$3 == 136 {print $1}' | sort | uniq > $POSITION_BUNDLE_PUBKEY
cat $POSITION_PUBKEY $POSITION_BUNDLE_PUBKEY > $CLOSABLE_PUBKEY

# extract all Position accounts (all versions)
$SNAPSHOT_GPA --pubkeyfile=$CLOSABLE_PUBKEY $SNAPSHOT > $CLOSABLE_DATA_ALL

# select latest write version
tail -n +2 $ALL_DATA_ALL > $MERGED_DATA_ALL
tail -n +2 $CLOSABLE_DATA_ALL >> $MERGED_DATA_ALL
cat $MERGED_DATA_ALL | sort -t, -k5,5nr | awk -F, '!dup[$1]++' > $MERGED_DATA_LATEST

# filter closed accounts
cat $MERGED_DATA_LATEST | awk -F, '$3 > 0 {print $0}' | sort -t, -k1 > $RESULT

# create gzipped file
gzip -c $RESULT > $RESULT.gz

