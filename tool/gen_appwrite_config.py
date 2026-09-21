#!/usr/bin/env python3
"""Régénère les sections tablesDB / tables / buckets de appwrite.config.json.

Le schéma est déclaré ici (source de vérité) ; le reste du fichier
(projet, settings, plateformes, functions) est conservé tel quel.
Ensuite : `appwrite push table -f && appwrite push bucket -f`.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "appwrite.config.json"
DB = "eco_responsable_db"

PERMS = ['read("any")', 'create("users")', 'update("users")', 'delete("users")']
INT_MIN, INT_MAX = -9223372036854775808, 9223372036854775807
DBL_MIN, DBL_MAX = -1.7976931348623157e308, 1.7976931348623157e308


def varchar(key, size=255, required=False, array=False, default=None):
    return {
        "key": key,
        "type": "varchar",
        "required": required,
        "array": array,
        "size": size,
        "default": None if required else default,
        "encrypt": False,
    }


def enum(key, elements, required=False, default=None):
    return {
        "key": key,
        "type": "string",
        "required": required,
        "array": False,
        "default": None if required else default,
        "format": "enum",
        "elements": elements,
    }


def integer(key, required=False, default=None):
    return {
        "key": key,
        "type": "integer",
        "required": required,
        "array": False,
        "default": None if required else default,
        "min": INT_MIN,
        "max": INT_MAX,
    }


def double(key, required=False):
    return {
        "key": key,
        "type": "double",
        "required": required,
        "array": False,
        "default": None,
        "min": DBL_MIN,
        "max": DBL_MAX,
    }


def boolean(key, required=False, default=None):
    return {
        "key": key,
        "type": "boolean",
        "required": required,
        "array": False,
        "default": None if required else default,
    }


def datetime_(key, required=False):
    return {
        "key": key,
        "type": "datetime",
        "required": required,
        "array": False,
        "default": None,
        "format": "",
    }


def index(key, columns):
    return {"key": key, "type": "key", "status": "available", "columns": columns, "orders": []}


def table(tid, name, columns, indexes=()):
    return {
        "$id": tid,
        "$permissions": PERMS,
        "databaseId": DB,
        "name": name,
        "enabled": True,
        "rowSecurity": True,
        "columns": columns,
        "indexes": list(indexes),
    }


def bucket(bid, name):
    return {
        "$id": bid,
        "$permissions": PERMS,
        "fileSecurity": True,
        "name": name,
        "enabled": True,
        "maximumFileSize": 10_000_000,
        "allowedFileExtensions": ["jpg", "jpeg", "png", "webp", "heic"],
        "compression": "none",
        "encryption": True,
        "antivirus": False,
    }


WASTE_TYPES = ["menager", "plastique", "electronique", "encombrant"]

TABLES = [
    table(
        "users",
        "Users",
        [
            varchar("name", 128),
            varchar("phone", 32),
            varchar("email", 128),
            varchar("city", 64, default="Yaoundé"),
            varchar("district", 64),
            enum("role", ["citizen", "collector", "admin"], default="citizen"),
            integer("points", default=0),
            varchar("language", 8, default="fr"),
            boolean("notificationsEnabled", default=True),
            varchar("avatarFileId", 64),
            varchar("level", 32, default="bronze"),
        ],
        [index("phone_idx", ["phone"]), index("role_idx", ["role"])],
    ),
    table(
        "waste_reports",
        "Waste reports",
        [
            varchar("authorId", 64, required=True),
            varchar("photoFileId", 64),
            double("lat", required=True),
            double("lng", required=True),
            enum("category", WASTE_TYPES, required=True),
            enum("urgency", ["faible", "moyen", "eleve", "critique"], required=True),
            enum("status", ["reported", "inProgress", "resolved"], default="reported"),
            varchar("address", 255),
            varchar("description", 1000),
            varchar("assignedOperatorId", 64),
            varchar("city", 64),
            datetime_("reportedAt"),
        ],
        [
            index("author_idx", ["authorId"]),
            index("status_idx", ["status"]),
            index("city_idx", ["city"]),
        ],
    ),
    table(
        "collection_requests",
        "Collection requests",
        [
            varchar("authorId", 64, required=True),
            enum("wasteType", WASTE_TYPES, required=True),
            enum("estimatedVolume", ["petit", "moyen", "grand", "tres_grand"], required=True),
            datetime_("scheduledAt"),
            enum(
                "status",
                ["pending", "matched", "enRoute", "collected", "cancelled"],
                default="pending",
            ),
            varchar("assignedCollectorId", 64),
            integer("amountPaid", default=0),
            boolean("isRecurring", default=False),
            varchar("paymentProvider", 32),
            double("weightKg"),
            varchar("proofFileId", 64),
            varchar("address", 255),
            varchar("timeSlot", 32),
        ],
        [
            index("author_req_idx", ["authorId"]),
            index("collector_idx", ["assignedCollectorId"]),
            index("req_status_idx", ["status"]),
        ],
    ),
    table(
        "collectors",
        "Collectors",
        [
            varchar("userId", 64, required=True),
            varchar("coveredZones", 64, array=True),
            boolean("isAvailable", default=False),
            integer("interventionsCount", default=0),
            varchar("displayName", 128),
            varchar("phone", 32),
            varchar("company", 128),
        ],
        [index("user_idx", ["userId"])],
    ),
    table(
        "reward_items",
        "Reward items",
        [
            enum("type", ["mobileMoneyCredit", "voucher", "partnerPerk"], required=True),
            integer("pointsCost", required=True),
            varchar("title", 128, required=True),
            varchar("description", 255),
            varchar("imageKey", 64),
            boolean("enabled", default=True),
        ],
    ),
    table(
        "zones",
        "Zones",
        [
            varchar("city", 64, required=True),
            varchar("district", 64, required=True),
            varchar("assignedOperators", 64, array=True),
            varchar("collectionFrequency", 64),
            varchar("color", 16),
            double("centerLat"),
            double("centerLng"),
        ],
    ),
    table(
        "notifications",
        "Notifications",
        [
            varchar("userId", 64, required=True),
            varchar("title", 128, required=True),
            varchar("body", 255),
            varchar("kind", 32),
            boolean("read", default=False),
            datetime_("createdAt"),
        ],
        [index("notif_user_idx", ["userId"])],
    ),
]

BUCKETS = [
    bucket("report_photos", "Report photos"),
    bucket("collection_proofs", "Collection proofs"),
]


def main() -> None:
    cfg = json.loads(CONFIG.read_text(encoding="utf-8"))
    cfg["tablesDB"] = [{"$id": DB, "name": "Eco Responsable DB", "enabled": True}]
    cfg["tables"] = TABLES
    cfg["buckets"] = BUCKETS
    CONFIG.write_text(json.dumps(cfg, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"{CONFIG.name}: {len(TABLES)} tables, {len(BUCKETS)} buckets")


if __name__ == "__main__":
    main()
