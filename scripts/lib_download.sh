#!/usr/bin/env bash
# Reusable download helpers with resume and verification
set -euo pipefail

# Usage: _dl_log LEVEL MSG
_dl_log() { printf '%s %s\n' "$1" "$2"; }

# Usage: get_header VALUE HEADER_NAME
# Reads a header value from a curl -I response
get_header() {
  printf '%s\n' "$1" | awk -v k="$2" 'BEGIN{IGNORECASE=1} tolower($0) ~ tolower(k ":") {sub(/^[^:]*:[ ]*/, ""); print; exit}'
}

# Usage: head_info URL [header1] [header2] ...
# Prints headers from a HEAD request
head_info() {
  local url="$1"; shift || true
  curl -fsI "$url" "$@"
}

# Usage: content_length URL [headers...]
content_length() {
  local out
  if out=$(head_info "$@" 2>/dev/null); then
    get_header "$out" "Content-Length"
  else
    echo ""
  fi
}

# Usage: sha256_file FILE
sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo ""
  fi
}

# Usage: verify_checksum FILE EXPECTED_SHA256
verify_checksum() {
  local f="$1"; local want="$2"
  [[ -z "$want" ]] && return 0
  local got
  got=$(sha256_file "$f" || true)
  [[ -n "$got" && "$got" == "$want" ]]
}

# Usage: download_with_resume URL TARGET [EXPECTED_SIZE] [EXPECTED_SHA256] [-- header ...]
# - Resumes downloads using curl -C -
# - If TARGET exists and matches size/checksum (when provided), skips
# - Downloads to TARGET.part then atomically moves into place
# - Returns 0 on success, non-zero on failure
download_with_resume() {
  local url="$1"; local target="$2"; local expect_size="${3:-}"; local expect_sha="${4:-}"; shift 4 || true
  local curl_headers=()
  if [[ "${1:-}" == "--" ]]; then shift; curl_headers=("$@"); fi

  mkdir -p "$(dirname "$target")"

  # If no expected size provided, try HEAD
  if [[ -z "$expect_size" ]]; then
    expect_size=$(content_length "$url" "${curl_headers[@]}" || true)
  fi

  if [[ -f "$target" ]]; then
    # If checksum provided, verify
    if verify_checksum "$target" "$expect_sha"; then
      _dl_log "✅" "Exists and checksum matches: $(basename "$target")"
      return 0
    fi
    # If size provided or probed, compare
    if [[ -n "$expect_size" ]]; then
      local have_size
      have_size=$(stat -c %s "$target" 2>/dev/null || echo 0)
      if [[ "$have_size" == "$expect_size" ]]; then
        _dl_log "✅" "Exists and size matches: $(basename "$target") ($have_size bytes)"
        return 0
      fi
    fi
    _dl_log "⏩" "Resuming: $(basename "$target")"
  fi

  local tmp="$target.part"
  # Resume with -C -; follow redirects; fail on HTTP errors; silent with progress bar
  if ! curl -fLS --retry 3 --retry-delay 2 -C - -o "$tmp" "${curl_headers[@]}" "$url"; then
    _dl_log "❌" "Download failed: $url"
    return 2
  fi

  # Verify size if known
  if [[ -n "$expect_size" ]]; then
    local got_size
    got_size=$(stat -c %s "$tmp" 2>/dev/null || echo 0)
    if [[ "$got_size" != "$expect_size" ]]; then
      _dl_log "⚠️" "Size mismatch for $(basename "$target"): got $got_size, want $expect_size"
      return 3
    fi
  fi

  # Verify checksum if provided
  if [[ -n "$expect_sha" ]]; then
    if ! verify_checksum "$tmp" "$expect_sha"; then
      _dl_log "⚠️" "Checksum mismatch for $(basename "$target")"
      return 4
    fi
  fi

  mv -f "$tmp" "$target"
  _dl_log "✅" "Downloaded: $(basename "$target")"
}

