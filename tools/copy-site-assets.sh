#!/bin/sh
# Run by Xcode on every build of the app (the "Copy the site's photos and the sample store" phase).
#
# Puts the site's photos that ship in the app (SiteAssets/: the tile cutouts and the home page's photos)
# into the app, and, in Debug builds reading the sample store, the sample store too (SampleStore/).
# Both folders are copied from the site by tools/sync-sample-store.sh and are git-ignored, as this repo is
# public (APP-SPEC.md §5). Release builds always leave the sample store out.
set -eu

dest="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
mkdir -p "$dest"

if [ -d "${SRCROOT}/SiteAssets" ]; then
  rsync -a --delete "${SRCROOT}/SiteAssets/" "${dest}/SiteAssets/"
elif [ "${CONFIGURATION}" = "Release" ]; then
  echo "error: SiteAssets/ is missing. Run tools/sync-sample-store.sh first."
  exit 1
else
  echo "warning: SiteAssets/ is missing, so the app has no tiles or home photos. Run tools/sync-sample-store.sh."
fi

if [ "${CONFIGURATION}" = "Debug" ] && [ "${SOS_STORE}" = "sample" ]; then
  if [ -d "${SRCROOT}/SampleStore" ]; then
    rsync -a --delete --exclude="/test/" "${SRCROOT}/SampleStore/" "${dest}/SampleStore/"
  else
    echo "warning: SampleStore/ is missing, so the sample store is empty. Run tools/sync-sample-store.sh."
  fi
else
  rm -rf "${dest}/SampleStore"
fi
