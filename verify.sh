#!/usr/bin/env bash
# Hash-verify the bundled artifacts of bcr-empirical-thresholds.
# Bundled files: enforced (script exits nonzero on any mismatch).
# Optional files (the two large bcr_paths_daily.csv outputs that are not bundled):
# expected hashes are documented; checks fire only if the file exists locally.
#
# Run from the repo root:
#   ./verify.sh
#
# Windows: run under Git Bash, WSL, or compare against the values below using
# `Get-FileHash -Algorithm SHA256`.

set -u

# Pick a sha256 binary. macOS ships `shasum`, Linux/Git-Bash ship `sha256sum`.
if command -v sha256sum >/dev/null 2>&1; then
    SHA="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    SHA="shasum -a 256"
else
    echo "ERROR: no sha256sum or shasum available on PATH." >&2
    exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

PASS=0
FAIL=0
SKIP=0

check() {
    # check <expected_sha> <relative_path>
    local expected="$1"
    local file="$2"
    local optional="${3:-required}"
    if [ ! -f "$file" ]; then
        if [ "$optional" = "optional" ]; then
            echo "[SKIP] $file (not present locally; regenerable from node scripts/export.js)"
            SKIP=$((SKIP + 1))
            return
        else
            echo "[FAIL] $file (missing)"
            FAIL=$((FAIL + 1))
            return
        fi
    fi
    local actual
    actual=$($SHA "$file" | awk '{print $1}')
    if [ "$actual" = "$expected" ]; then
        echo "[PASS] $file"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $file"
        echo "       expected: $expected"
        echo "       got:      $actual"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Bundled files (enforced) ==="

# Engine + scripts
check 2f9bffd383288b75e79c59bc73abfbf9b2f938261cb6a3960babd3b24f849fcf src/solvency-engine.js
check 37263751c836134d5f61f0302b4f96d35eb92b86a05c7dda2f9c54c9c6f42bfe scripts/preprocess-bitstamp.js
check 6016b07b00e0439d0891c62600f19d2984b53dbb95cee08cd825abfb203226e7 scripts/export.js
check 6781eabbeec0a4dcbfd9d37df9f796e38d07a915c606755db9ac9b30a49a8e1a scripts/lib/engine.js
check cd76b8dde9d25a9422d55e72cb0dabf07b20cc1064870e585b325064f227ac9d scripts/lib/runner.js
check c5f0b34b30bb51302f60109af24dac1a7d1979864d7da6b72435ee6c476f5539 scripts/lib/aggregator.js
check 3fc55a9fa75318a2f1e360bbf9b4801cf945d167aac60c88c62d147302aa272c scripts/lib/monthly.js
check 747a89f3421fd0f4db8d8c173820e792ee7de7fe7f1da30d9a688790e180c82e scripts/lib/prices.js
check 531a50fbd15b35f3d86a99ad68c7604645b87b575fd3dd7a8019daf13cb20c7c scripts/lib/regimes.js
check e346d8e686bc00b658f4aa953ffba344240bf092830ace380d1293cf7235ecec scripts/lib/stats.js
check d4293ab598c2daeb27c97329de6af41c30b1f06136ca21127ec9bdd913aa906c scripts/lib/writers.js
check 500cc725eb869fa9b67d9dcfe4d71744069c1e3d5341cfe232b646ee373986f2 scripts/derive-mech-chart-data.js
check 60b995e14a2bcda59ef760b789e97e7be1fea0bf25134d4c269647e665766b2c scripts/build-surface.js
check 8d4a0121d85ae78dfb3422ca650f941a197941296389398f1f03f4ee9b7ae371 scripts/build-surface-grid-validation.js
check 67964e9e51b8af26d4a953dd1e9c832dce4adf2f0f94a92712900b1321c2c007 scripts/bake-viewer.js

# Interactive viewer (snapshot of outputs/surface_grid.csv; regenerable via scripts/bake-viewer.js)
check 19e2026cea45edb95e48570f951c1582cc90c9b4ce8aeabadd984b7c7a5ee8a5 bcr_3d_viewer.html

# Price sources (cited in paper Appendix C)
check 978ad50a50bf22be09d9a18b1517202d71f15cea7bed46d93e445a3af1810146 data/btc-prices-bitstamp.csv
check e485212cb35e1a37a8db3bb388f04ddf8ff294708238752fbfb02f3e1d02d6ec data/btc-prices-bitstamp-imputation.json
check 690e81b45a03c35b45a907a1baab2e44532f33ac4c5c5f152457f3c1b63e1eba data/btc-prices-coinmetrics.csv
check 94e9e11b9aa931fcbd64f1984b708206ec961133b1ef2b026717afcce5325c6b data/raw/bitstamp_btc_prices.csv

# Bundled outputs (monthly cadence)
check 0c14bac5fc69a492a19b6c784bd7c77646db3e7c7b867e2ce3669ce92754f199 outputs/regime_summary.csv
check f04964aa241aabf69ff9cf0cc71b874249be31d5015e952bbc43dcf2df97299e outputs/regime_descriptors.csv
check 1474eef83928592e5636a80516083711bf2fc8f9ee2815fe0241122dac510332 outputs/bcr_paths_monthly.csv
check 607d7fe2376f7cc26620f11dc78342d386d4cd403dbdf7f7e4d7e3cec3b35a3b outputs/transition_paths_monthly.csv
check c76efa94fa5086526d545676649eab2e3bb3f8d4c1a219fdb55e224694d8da10 outputs/min_bcr_chart_data_mech.csv

# Bundled outputs (surface build, paper §6.5)
check 77f1454383b82821bbda3d6e8a66aa1100fffda11d9aaa026756873b2e25bef5 outputs/regime_tau_sigma.csv
check e6dcee1bed5a26a371252bf4d22083be1ecdb61ab182dafe7676088cd53f227f outputs/time_at_depth_distributions.csv
check 88679022548f837b78047015768000846894795d6f51d363197a73104299bd2f outputs/surface_validation.csv
check de74af773efd25f7ba7cba7024795917b4aa4b52e479795f592ba2f89f32d433 outputs/surface_grid.csv
check ddcdb48e8c76f33ad41c98a81e8a72187c03623e5c00f1ab3d2e4a1dc23c952e outputs/surface_grid_validation.csv

# Bundled outputs (daily cadence)
check f2cea5687e90bb5d6401b381ecb92e040a5dbe0d81c794b70c789ffe378ec12a outputs/daily/regime_summary.csv
check 136cfbc714e9ea0f6b735a02f8248da2c134291140d809bd20158d8511bfca11 outputs/daily/regime_descriptors.csv
check cbb1e64397ca7af491adb62c3d4033dd68e510fe007cb477854f32d154cf87da outputs/daily/bcr_paths_monthly.csv
check 311ea0aad4fdb919a047c89aadb803838cd2956066e78f77731078407c996fca outputs/daily/transition_paths_monthly.csv
check 9b78f4f5c86184b0e1f786e3c880b5cab300987ab31c8835e3b61a69447c8440 outputs/daily/min_bcr_chart_data_mech.csv

# manifest.json: contents include a wall-clock run_timestamp, so SHA depends on
# when the bundled run happened. The bundled hashes below are for the published
# snapshot; if you re-run the export locally, your manifest.json hash will
# legitimately differ and these two checks will FAIL by design. Skip them in
# that case; the bundled snapshot manifests are kept for reviewer reference.
check e67b1008d64791bcbb2493db0c164c3e2ea762c2e088bba3b272cb38eae2db5d outputs/manifest.json
check 50e27eb51f57d36a35d92e62c7900f97c7746c338b177f6e82d7f7f09cb75eb4 outputs/daily/manifest.json

echo
echo "=== Optional / regenerable files (only checked if present) ==="

# bcr_paths_daily.csv files are not bundled (over GitHub's 100 MB per-file limit).
# Run `node scripts/export.js` and `node scripts/export.js --cadence=daily` to regenerate.
check c3fb518c8f53c5144b83ed58eba06df15acd319e5446e0f8f7fc4b2467e97458 outputs/bcr_paths_daily.csv optional
check 6a814c9b80ababb7783782e5f9dc9ada3b74c7b97a6cbfc8724e22a3b1c76caf outputs/daily/bcr_paths_daily.csv optional

echo
echo "=== Summary ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  SKIP: $SKIP (regenerable from node scripts/export.js; not bundled)"
echo

if [ "$FAIL" -gt 0 ]; then
    echo "RESULT: $FAIL file(s) failed verification."
    exit 1
fi
echo "RESULT: ALL BUNDLED FILES PASS"
exit 0
