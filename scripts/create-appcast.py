#!/usr/bin/env python3
"""Write Nova OS's Sparkle appcast entry for a pre-signed update archive."""

import datetime as dt
import email.utils
import sys
import urllib.parse
import xml.etree.ElementTree as ET
from pathlib import Path


archive = Path(sys.argv[1])
feed_path = Path(sys.argv[2])
short_version = sys.argv[3]
build_version = sys.argv[4]
signature = sys.argv[5]
download_prefix = sys.argv[6].rstrip("/") + "/"
repo_url = sys.argv[7]
sparkle_ns = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", sparkle_ns)

root = ET.Element("rss", {"version": "2.0"})
channel = ET.SubElement(root, "channel")
ET.SubElement(channel, "title").text = "Nova OS Updates"
ET.SubElement(channel, "link").text = repo_url
ET.SubElement(channel, "description").text = "Updates for Nova OS for Mac"
ET.SubElement(channel, "language").text = "en"

item = ET.SubElement(channel, "item")
ET.SubElement(item, "title").text = f"Nova OS {short_version}"
ET.SubElement(item, "pubDate").text = email.utils.format_datetime(dt.datetime.now().astimezone())
ET.SubElement(item, f"{{{sparkle_ns}}}version").text = build_version
ET.SubElement(item, f"{{{sparkle_ns}}}shortVersionString").text = short_version
ET.SubElement(item, f"{{{sparkle_ns}}}minimumSystemVersion").text = "13.0.0"

description_html = (
    "<h2>New in Nova OS " + short_version + "</h2>"
    "<ul>"
    "<li>Nova restores your open tabs at the next launch.</li>"
    "<li>Save and open bookmarks from the star button and Bookmarks menu.</li>"
    "<li>Recent results return instantly when you reopen a search tab.</li>"
    "</ul>"
)
ET.SubElement(item, "description").text = "NOVA_RELEASE_NOTES"

archive_url = download_prefix + urllib.parse.quote(archive.name, safe="")
ET.SubElement(
    item,
    "enclosure",
    {
        "url": archive_url,
        "length": str(archive.stat().st_size),
        "type": "application/octet-stream",
        f"{{{sparkle_ns}}}edSignature": signature,
    },
)

ET.indent(root, space="  ")
feed_path.parent.mkdir(parents=True, exist_ok=True)
serialized = ET.tostring(root, encoding="unicode", xml_declaration=True)
serialized = serialized.replace(
    "<description>NOVA_RELEASE_NOTES</description>",
    "<description><![CDATA[" + description_html + "]]></description>",
)
feed_path.write_text(serialized + "\n", encoding="utf-8")
