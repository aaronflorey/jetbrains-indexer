#/bin/sh

echo_format() {
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

# Generate indexes (dump-shared-index)
echo_format "Generating indexes"

/opt/index-tool/bin/ij-shared-indexes-tool-cli indexes \
    --ij /opt/idea \
    --project ${IDEA_PROJECT_DIR} \
    --base-url ${INDEXES_CDN_URL} \
    --data-directory ${SHARED_INDEX_BASE}