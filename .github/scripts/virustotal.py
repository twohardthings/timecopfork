#!/usr/bin/env python3
"""Uploads APKs to VirusTotal and prints a Markdown summary of the scans.

Usage: virustotal.py FILE...

Needs the API key in VT_API_KEY. Uses only the standard library, so the
key goes straight to VirusTotal's API and no third-party code sees it.

The free API allows 4 requests a minute, so requests are spaced out. Files
are reported as "scan in progress" with a link if the scan isn't finished
after VT_TIMEOUT seconds (default 900); the link shows the result later.
"""

import hashlib
import http.client
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid

API = os.environ.get("VT_API_URL", "https://www.virustotal.com/api/v3")
GUI = "https://www.virustotal.com/gui/file/"
KEY = os.environ["VT_API_KEY"]
SPACING = float(os.environ.get("VT_SPACING", "16"))  # seconds between requests
RETRY_WAIT = float(os.environ.get("VT_RETRY_WAIT", "60"))  # after a 429 or error
TIMEOUT = float(os.environ.get("VT_TIMEOUT", "900"))  # for waiting on the scans
DIRECT_UPLOAD_LIMIT = 32 * 1024 * 1024  # bigger files need an upload URL

_last_request = 0.0


class DeadlineExceeded(Exception):
    """The time for waiting on the scans ran out."""


def _sleep(seconds, deadline):
    if deadline is not None and time.monotonic() + seconds >= deadline:
        raise DeadlineExceeded()
    if seconds > 0:
        time.sleep(seconds)


def request(method, url, data=None, headers=None, deadline=None):
    """Sends one API request, keeping to the rate limit and retrying rate
    limits (429) and transient network errors a few times.

    With a deadline (a time.monotonic() value), no wait or request runs past
    it; DeadlineExceeded is raised instead.
    """
    global _last_request
    for attempt in range(6):
        _sleep(_last_request + SPACING - time.monotonic(), deadline)
        timeout = 300.0
        if deadline is not None:
            timeout = min(timeout, deadline - time.monotonic())
            if timeout <= 0:
                raise DeadlineExceeded()
        _last_request = time.monotonic()
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("x-apikey", KEY)
        req.add_header("accept", "application/json")
        for name, value in (headers or {}).items():
            req.add_header(name, value)
        try:
            with urllib.request.urlopen(req, timeout=timeout) as response:
                return json.load(response)
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 5:
                _sleep(RETRY_WAIT, deadline)  # quota for this minute used up
                continue
            body = e.read().decode("utf-8", "replace")[:500]
            raise SystemExit(f"VirusTotal {method} {url}: HTTP {e.code}: {body}")
        except (
            urllib.error.URLError,  # e.g. connection refused, DNS
            http.client.HTTPException,  # e.g. IncompleteRead, RemoteDisconnected
            ConnectionError,  # e.g. connection reset while reading
            TimeoutError,  # read timeout
        ) as e:
            reason = getattr(e, "reason", None) or repr(e)
            if attempt < 5:
                print(f"{method} {url} failed ({reason}), retrying", file=sys.stderr)
                _sleep(RETRY_WAIT / 2, deadline)
                continue
            raise SystemExit(f"VirusTotal {method} {url}: {reason}")


def upload(path):
    """Uploads a file and returns the analysis ID."""
    with open(path, "rb") as f:
        content = f.read()
    url = API + "/files"
    if len(content) > DIRECT_UPLOAD_LIMIT:
        url = request("GET", API + "/files/upload_url")["data"]
    boundary = uuid.uuid4().hex
    name = os.path.basename(path)
    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="file"; filename="{name}"\r\n'
        "Content-Type: application/vnd.android.package-archive\r\n\r\n"
    ).encode() + content + f"\r\n--{boundary}--\r\n".encode()
    result = request(
        "POST",
        url,
        data=body,
        headers={"content-type": f"multipart/form-data; boundary={boundary}"},
    )
    return result["data"]["id"]


def main(paths):
    files = []
    for path in paths:
        if not os.path.isfile(path):
            raise SystemExit(f"No such file: {path}")
        with open(path, "rb") as f:
            sha256 = hashlib.sha256(f.read()).hexdigest()
        print(f"Uploading {path} ({sha256})", file=sys.stderr)
        files.append({"path": path, "sha256": sha256, "analysis": upload(path)})

    deadline = time.monotonic() + TIMEOUT
    pending = list(files)
    try:
        while pending:
            for file in list(pending):
                result = request(
                    "GET", API + "/analyses/" + file["analysis"], deadline=deadline
                )
                attributes = result["data"]["attributes"]
                if attributes.get("status") == "completed":
                    file["stats"] = attributes["stats"]
                    pending.remove(file)
                    print(f"Scanned {file['path']}: {file['stats']}", file=sys.stderr)
    except DeadlineExceeded:
        print(f"Stopped waiting; {len(pending)} scan(s) not finished", file=sys.stderr)

    print("### VirusTotal")
    print()
    print("| APK | Result |")
    print("| --- | --- |")
    for file in files:
        link = GUI + file["sha256"]
        name = os.path.basename(file["path"])
        stats = file.get("stats")
        if stats is None:
            result = f"[scan in progress]({link})"
        else:
            flagged = stats.get("malicious", 0) + stats.get("suspicious", 0)
            # engines that gave a verdict; "unsupported" and timeouts don't count
            engines = flagged + stats.get("undetected", 0) + stats.get("harmless", 0)
            result = f"[{flagged} / {engines} engines flagged it]({link})"
        print(f"| `{name}` | {result} |")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(sys.argv[1:])
