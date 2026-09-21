#!/usr/bin/env python3
"""Provisionne la base Appwrite Éco-Responsable (clé serveur, jamais dans Flutter).

Hérité de l'instance auto-hébergée (API Databases). Sur Appwrite Cloud,
préférer `tool/appwrite_cli_init.sh` (CLI + appwrite.config.json).
"""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request

ENDPOINT = os.environ.get(
    "APPWRITE_ENDPOINT", "https://fra.cloud.appwrite.io/v1"
).rstrip("/")
PROJECT = os.environ.get("APPWRITE_PROJECT_ID", "eco-responsable-cm")
API_KEY = os.environ.get("APPWRITE_API_KEY")
DB = "eco_responsable_db"

if not API_KEY:
    raise SystemExit("APPWRITE_API_KEY est obligatoire pour provisionner Appwrite.")


def req(method: str, path: str, body: dict | None = None, ok: tuple[int, ...] = (200, 201, 204)):
    data = None if body is None else json.dumps(body).encode()
    r = urllib.request.Request(
        f"{ENDPOINT}{path}",
        data=data,
        method=method,
        headers={
            "Content-Type": "application/json",
            "X-Appwrite-Project": PROJECT,
            "X-Appwrite-Key": API_KEY,
        },
    )
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            raw = resp.read()
            print(method, path, resp.status)
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        payload = e.read().decode(errors="replace")
        if e.code in (409,):
            print("exists", path)
            return {"$exists": True}
        if e.code in ok:
            return {}
        print("ERR", method, path, e.code, payload[:500], file=sys.stderr)
        if e.code in (401, 403):
            raise
        return {"error": e.code, "body": payload}


def wait_attr(col: str, key: str) -> None:
    for _ in range(30):
        doc = req("GET", f"/databases/{DB}/collections/{col}/attributes/{key}")
        status = doc.get("status")
        if status == "available":
            return
        if status == "failed":
            print("attr failed", col, key, doc)
            return
        time.sleep(0.6)


def string_attr(col: str, key: str, size: int = 255, required: bool = False, array: bool = False, default=None):
    body = {"key": key, "size": size, "required": required, "array": array}
    if default is not None and not required:
        body["default"] = default
    req("POST", f"/databases/{DB}/collections/{col}/attributes/string", body)
    wait_attr(col, key)


def int_attr(col: str, key: str, required: bool = False, default=None):
    body = {"key": key, "required": required, "min": -2147483647, "max": 2147483647}
    if default is not None and not required:
        body["default"] = default
    req("POST", f"/databases/{DB}/collections/{col}/attributes/integer", body)
    wait_attr(col, key)


def float_attr(col: str, key: str, required: bool = False):
    req(
        "POST",
        f"/databases/{DB}/collections/{col}/attributes/float",
        {"key": key, "required": required, "min": -180, "max": 180},
    )
    wait_attr(col, key)


def bool_attr(col: str, key: str, required: bool = False, default=None):
    body = {"key": key, "required": required}
    if default is not None and not required:
        body["default"] = default
    req("POST", f"/databases/{DB}/collections/{col}/attributes/boolean", body)
    wait_attr(col, key)


def dt_attr(col: str, key: str, required: bool = False):
    req("POST", f"/databases/{DB}/collections/{col}/attributes/datetime", {"key": key, "required": required})
    wait_attr(col, key)


def enum_attr(col: str, key: str, elements: list[str], required: bool = False, default=None):
    body = {"key": key, "elements": elements, "required": required}
    if default is not None and not required:
        body["default"] = default
    req("POST", f"/databases/{DB}/collections/{col}/attributes/enum", body)
    wait_attr(col, key)


def collection(cid: str, name: str) -> None:
    req(
        "POST",
        f"/databases/{DB}/collections",
        {
            "collectionId": cid,
            "name": name,
            "documentSecurity": True,
            "permissions": [
                'read("any")',
                'create("users")',
                'update("users")',
                'delete("users")',
            ],
            "enabled": True,
        },
    )


def index(col: str, key: str, attrs: list[str]) -> None:
    req(
        "POST",
        f"/databases/{DB}/collections/{col}/indexes",
        {"key": key, "type": "key", "attributes": attrs},
    )


def bucket(bid: str, name: str) -> None:
    req(
        "POST",
        "/storage/buckets",
        {
            "bucketId": bid,
            "name": name,
            "permissions": [
                'read("any")',
                'create("users")',
                'update("users")',
                'delete("users")',
            ],
            "fileSecurity": True,
            "enabled": True,
            "maximumFileSize": 10_000_000,
            "allowedFileExtensions": ["jpg", "jpeg", "png", "webp", "heic"],
            "encryption": True,
            "antivirus": False,
        },
    )


def platform(ptype: str, name: str, key: str) -> None:
    req(
        "POST",
        f"/projects/{PROJECT}/platforms",
        {"type": ptype, "name": name, "key": key},
    )


def seed_doc(col: str, did: str, data: dict) -> None:
    req(
        "POST",
        f"/databases/{DB}/collections/{col}/documents",
        {
            "documentId": did,
            "data": data,
            "permissions": ['read("any")', 'update("users")', 'delete("users")'],
        },
    )


def main() -> None:
    req("POST", "/databases", {"databaseId": DB, "name": "Eco Responsable DB", "enabled": True})

    collection("users", "Users")
    string_attr("users", "name", 128)
    string_attr("users", "phone", 32)
    string_attr("users", "email", 128)
    string_attr("users", "city", 64, default="Yaoundé")
    string_attr("users", "district", 64)
    enum_attr("users", "role", ["citizen", "collector", "admin"], default="citizen")
    int_attr("users", "points", default=0)
    string_attr("users", "language", 8, default="fr")
    bool_attr("users", "notificationsEnabled", default=True)
    string_attr("users", "avatarFileId", 64)
    string_attr("users", "level", 32, default="bronze")
    index("users", "phone_idx", ["phone"])
    index("users", "role_idx", ["role"])

    collection("waste_reports", "Waste reports")
    string_attr("waste_reports", "authorId", 64, required=True)
    string_attr("waste_reports", "photoFileId", 64)
    float_attr("waste_reports", "lat", required=True)
    float_attr("waste_reports", "lng", required=True)
    enum_attr("waste_reports", "category", ["menager", "plastique", "electronique", "encombrant"], required=True)
    enum_attr("waste_reports", "urgency", ["faible", "moyen", "eleve", "critique"], required=True)
    enum_attr("waste_reports", "status", ["reported", "inProgress", "resolved"], default="reported")
    string_attr("waste_reports", "address", 255)
    string_attr("waste_reports", "description", 1000)
    string_attr("waste_reports", "assignedOperatorId", 64)
    string_attr("waste_reports", "city", 64)
    dt_attr("waste_reports", "reportedAt")
    index("waste_reports", "author_idx", ["authorId"])
    index("waste_reports", "status_idx", ["status"])
    index("waste_reports", "city_idx", ["city"])

    collection("collection_requests", "Collection requests")
    string_attr("collection_requests", "authorId", 64, required=True)
    enum_attr("collection_requests", "wasteType", ["menager", "plastique", "electronique", "encombrant"], required=True)
    enum_attr("collection_requests", "estimatedVolume", ["petit", "moyen", "grand", "tres_grand"], required=True)
    dt_attr("collection_requests", "scheduledAt")
    enum_attr("collection_requests", "status", ["pending", "matched", "enRoute", "collected", "cancelled"], default="pending")
    string_attr("collection_requests", "assignedCollectorId", 64)
    int_attr("collection_requests", "amountPaid", default=0)
    bool_attr("collection_requests", "isRecurring", default=False)
    string_attr("collection_requests", "paymentProvider", 32)
    float_attr("collection_requests", "weightKg")
    string_attr("collection_requests", "proofFileId", 64)
    string_attr("collection_requests", "address", 255)
    string_attr("collection_requests", "timeSlot", 32)
    index("collection_requests", "author_req_idx", ["authorId"])
    index("collection_requests", "collector_idx", ["assignedCollectorId"])
    index("collection_requests", "req_status_idx", ["status"])

    collection("collectors", "Collectors")
    string_attr("collectors", "userId", 64, required=True)
    string_attr("collectors", "coveredZones", 64, array=True)
    bool_attr("collectors", "isAvailable", default=False)
    int_attr("collectors", "interventionsCount", default=0)
    string_attr("collectors", "displayName", 128)
    string_attr("collectors", "phone", 32)
    string_attr("collectors", "company", 128)
    index("collectors", "user_idx", ["userId"])

    collection("reward_items", "Reward items")
    enum_attr("reward_items", "type", ["mobileMoneyCredit", "voucher", "partnerPerk"], required=True)
    int_attr("reward_items", "pointsCost", required=True)
    string_attr("reward_items", "title", 128, required=True)
    string_attr("reward_items", "description", 255)
    string_attr("reward_items", "imageKey", 64)
    bool_attr("reward_items", "enabled", default=True)

    collection("zones", "Zones")
    string_attr("zones", "city", 64, required=True)
    string_attr("zones", "district", 64, required=True)
    string_attr("zones", "assignedOperators", 64, array=True)
    string_attr("zones", "collectionFrequency", 64)
    string_attr("zones", "color", 16)
    float_attr("zones", "centerLat")
    float_attr("zones", "centerLng")

    collection("notifications", "Notifications")
    string_attr("notifications", "userId", 64, required=True)
    string_attr("notifications", "title", 128, required=True)
    string_attr("notifications", "body", 255)
    string_attr("notifications", "kind", 32)
    bool_attr("notifications", "read", default=False)
    dt_attr("notifications", "createdAt")
    index("notifications", "notif_user_idx", ["userId"])

    bucket("report_photos", "Report photos")
    bucket("collection_proofs", "Collection proofs")

    for ptype, name in [
        ("flutter-android", "eco-respo android"),
        ("flutter-ios", "eco-respo ios"),
        ("flutter-linux", "eco-respo linux"),
        ("flutter-macos", "eco-respo macos"),
        ("flutter-windows", "eco-respo windows"),
    ]:
        platform(ptype, name, "com.eco.kf")

    seed_doc(
        "reward_items",
        "rw_mtn",
        {
            "type": "mobileMoneyCredit",
            "pointsCost": 1000,
            "title": "Crédit Mobile MoMo",
            "description": "À partir de 1 000 pts",
            "imageKey": "reward_mtn",
            "enabled": True,
        },
    )
    seed_doc(
        "reward_items",
        "rw_voucher",
        {
            "type": "voucher",
            "pointsCost": 1500,
            "title": "Bons d'achat",
            "description": "À partir de 1 500 pts",
            "imageKey": "reward_voucher",
            "enabled": True,
        },
    )
    seed_doc(
        "reward_items",
        "rw_partner",
        {
            "type": "partnerPerk",
            "pointsCost": 2000,
            "title": "Avantages partenaires",
            "description": "À partir de 2 000 pts",
            "imageKey": "reward_partner",
            "enabled": True,
        },
    )

    zones = [
        ("z_centre", "Centre", "Zone 1", "#7E57C2", 3.866, 11.516),
        ("z_nord", "Nord", "Zone 2", "#5C6BC0", 3.915, 11.52),
        ("z_est", "Est", "Zone 3", "#26A69A", 3.86, 11.56),
        ("z_ouest", "Ouest", "Zone 4", "#66BB6A", 3.86, 11.47),
        ("z_sud", "Sud", "Zone 5", "#42A5F5", 3.80, 11.52),
    ]
    for zid, district, name, color, lat, lng in zones:
        seed_doc(
            "zones",
            zid,
            {
                "city": "Yaoundé",
                "district": district,
                "assignedOperators": [],
                "collectionFrequency": "2x / semaine",
                "color": color,
                "centerLat": lat,
                "centerLng": lng,
            },
        )

    print("Appwrite setup terminé.")


if __name__ == "__main__":
    main()
