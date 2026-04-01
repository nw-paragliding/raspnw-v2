#!/bin/bash
# Download wrfsi GEOG data for NW quadrant (N. hemisphere, W. longitudes)
# Required for gridgen_model.exe to generate WAHRRR domain static files.
# Total: ~80MB. Run once; output wrfstatic_d01 is cached in domain/static/.

set -e

BASE_URL="ftp://aftp.fsl.noaa.gov/divisions/frd-laps/WRFSI/Geog_Data"
GEOG_DIR="$(dirname "$0")/../../WRF/wrfsi/extdata/GEOG"
GEOG_DIR="$(cd "$GEOG_DIR" && pwd)"

echo "Downloading wrfsi GEOG data to: $GEOG_DIR"
cd "$GEOG_DIR"

download_and_extract() {
    local dir="$1"
    local file="$2"
    local url="${BASE_URL}/${dir}/${file}"
    if [ -d "${dir}" ] && [ "$(ls -A ${dir} 2>/dev/null | grep -v README | wc -l)" -gt 0 ]; then
        echo "  $dir already populated, skipping"
        return
    fi
    echo "  Downloading $file..."
    curl -s -O "$url"
    echo "  Extracting $file..."
    tar -xzf "$file"
    rm -f "$file"
    echo "  Done: $dir"
}

download_global() {
    local file="$1"
    local dir="${file%.tar.tgz}"
    dir="${dir%.tar.gz}"
    if [ -d "${dir}" ] && [ "$(ls -A ${dir} 2>/dev/null | grep -v README | wc -l)" -gt 0 ]; then
        echo "  $dir already populated, skipping"
        return
    fi
    echo "  Downloading $file..."
    curl -s -O "${BASE_URL}/${file}"
    echo "  Extracting $file..."
    tar -xzf "$file"
    rm -f "$file"
    echo "  Done: $dir"
}

# NW quadrant (Northern hemisphere, Western longitudes — covers Washington state)
echo "NW quadrant tiles..."
download_and_extract "topo_30s"        "topo_30s.NW.tar.tgz"
download_and_extract "landuse_30s"     "landuse_30s.NW.tar.tgz"
download_and_extract "soiltype_bot_30s" "soiltype_bot_30s.NW.tar.tgz"
download_and_extract "soiltype_top_30s" "soiltype_top_30s.NW.tar.tgz"

# Global datasets (small)
echo "Global datasets..."
download_global "greenfrac.tar.tgz"
download_global "albedo_ncep.tar.tgz"
download_global "islope.tar.tgz"
download_global "maxsnowalb.tar.tgz"
download_global "soiltemp_1deg.tar.tgz"

echo ""
echo "GEOG data download complete."
echo "Directory contents:"
ls -lh "$GEOG_DIR"
