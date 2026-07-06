#!/usr/bin/env bash
# Capture the walkthrough screenshots from the committed static pages.
# Requires a chrome/chromium binary; pages are local files, no network.
set -euo pipefail
cd "$(dirname "$0")/.."

CHROME=$(command -v google-chrome || command -v chromium || command -v chromium-browser)
SHOT="$CHROME --headless=new --disable-gpu --no-sandbox"

$SHOT --window-size=1180,2400 --screenshot=walkthrough/img/n3-comparison-page.png "file://$PWD/site/index.html"
$SHOT --window-size=1400,950 --screenshot=walkthrough/img/dashboard-now.png "file://$PWD/site/dashboard.html"
echo "screenshots -> walkthrough/img/"
