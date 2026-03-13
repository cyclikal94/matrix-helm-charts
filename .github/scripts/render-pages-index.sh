#!/usr/bin/env bash
set -euo pipefail

readme_path="${1:-README.md}"
output_path="${2:-index.md}"

if [ ! -f "${readme_path}" ]; then
  echo "README file not found: ${readme_path}" >&2
  exit 1
fi

site_title="$(sed -n 's/^# //p' "${readme_path}" | head -n 1)"
if [ -z "${site_title}" ]; then
  site_title="Matrix Helm Charts"
fi

{
  echo "---"
  echo "layout: page"
  echo "title: ${site_title}"
  echo "---"
  echo

  awk '
    BEGIN {
      skipped_h1 = 0
      dropped_overview = 0
      in_admonition = 0
    }
    {
      if (in_admonition) {
        if ($0 ~ /^>/) {
          line = $0
          sub(/^> ?/, "", line)
          print line
          next
        }

        print "</div>"
        print ""
        in_admonition = 0
      }

      if (!skipped_h1 && $0 ~ /^# /) {
        skipped_h1 = 1
        next
      }

      if (!dropped_overview) {
        if ($0 ~ /^[[:space:]]*$/) {
          next
        }
        if ($0 ~ /^## Overview[[:space:]]*$/) {
          dropped_overview = 1
          next
        }
        dropped_overview = 1
      }

      if ($0 ~ /^> \[![A-Z]+\][[:space:]]*$/) {
        label = $0
        sub(/^> \[!/, "", label)
        sub(/\][[:space:]]*$/, "", label)
        class_name = tolower(label)
        label = toupper(substr(label, 1, 1)) tolower(substr(label, 2))
        print "<div class=\"pages-callout pages-callout-" class_name "\" markdown=\"1\">"
        print "<p class=\"pages-callout-title\">" label "</p>"
        print ""
        in_admonition = 1
        next
      }

      print
    }
    END {
      if (in_admonition) {
        print "</div>"
      }
    }
  ' "${readme_path}"
} | perl -pe 's{<t([dh])\b(?![^>]*\bmarkdown=)([^>]*)>}{<t$1 markdown="1"$2>}g' > "${output_path}"
