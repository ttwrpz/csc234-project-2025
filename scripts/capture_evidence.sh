#!/bin/bash
# MoodBloom v1.0 - Evidence Capture Script
# Run from the project root directory.

set -e

EVIDENCE_DIR="evidence"
mkdir -p "$EVIDENCE_DIR"

echo "=== MoodBloom v1.0 Evidence Capture ==="
echo ""

# 1. Run flutter analyze
echo "--- Static Analysis ---"
flutter analyze 2>&1 | tee "$EVIDENCE_DIR/analyze_results.txt"
echo ""

# 2. Run all unit + widget tests
echo "--- Unit & Widget Tests ---"
flutter test --reporter expanded 2>&1 | tee "$EVIDENCE_DIR/test_results_unit.txt"
echo ""

# 3. Run integration tests on Chrome (if available)
echo "--- Integration Tests (Web) ---"
flutter test integration_test/app_test.dart -d chrome 2>&1 | tee "$EVIDENCE_DIR/test_results_web.txt" || echo "Web integration tests require device support"
echo ""

# 4. Summary
echo "=== Evidence Capture Complete ==="
echo ""
echo "Files saved to $EVIDENCE_DIR/:"
ls -la "$EVIDENCE_DIR/"
echo ""
echo "Next steps:"
echo "  1. Take screenshots of the app running on Android (Home, Log Mood, History, Settings)"
echo "  2. Take screenshots of the app running on Chrome (same 4 screens)"
echo "  3. Save screenshots to $EVIDENCE_DIR/"
