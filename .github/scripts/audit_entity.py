#!/usr/bin/env python3
"""Audit + apply one data operation (create / update / delete) for the RPG repo.

All inputs arrive through environment variables (never interpolated into a shell
command):

  RPG_ACTION, RPG_ENTITY_TYPE, RPG_ENTITY_ID, RPG_OPERATION_ID, RPG_PAYLOAD (JSON)

Data lives in branches.json / activities.json / records.json. The outcome of every
operation is written to status/<operation_id>.json so the app can look up exactly
the operation it started (PENDING = file not there yet).
Outcomes: SUCCESS, REJECTED (validation / duplicate), FAILED (unexpected error).
"""

import json
import math
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

OP_ID_RE = re.compile(r"^[A-Za-z0-9_-]{1,64}$")
MAX_STATUS_FILES = 100
ACTIONS = ("create", "update", "delete")
FILES = {"branch": "branches.json", "activity": "activities.json", "record": "records.json"}


NUMERIC_TYPES = ("number", "duration")


def _is_num(v: Any) -> bool:
    """A JSON number. bool is an int in Python but never a number here."""
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def goal_xp(base_xp: int, value: float, goal: float) -> int:
    """Points for a record against a goal: floor(base*value/goal + 0.5); 0 when value <= 0.

    Must match goalXp in lib/src/domain/goals.dart."""
    if value <= 0:
        return 0
    return math.floor(base_xp * value / goal + 0.5)


def _norm(s: Any) -> str:
    return str(s or "").strip().lower()


class EntityAuditor:
    def __init__(self, repo_root: str = "."):
        self.root = Path(repo_root)
        self.branches = self._load("branch")
        self.activities = self._load("activity")
        self.records = self._load("record")

    # ---- persistence -------------------------------------------------
    def _path(self, etype: str) -> Path:
        return self.root / FILES[etype]

    def _load(self, etype: str) -> List[Dict[str, Any]]:
        p = self._path(etype)
        if not p.exists():
            return []
        try:
            data = json.loads(p.read_text(encoding="utf-8") or "[]")
        except json.JSONDecodeError:
            raise RuntimeError(f"{p.name} is corrupt JSON; refusing to overwrite")
        return data if isinstance(data, list) else []

    def _save(self, etype: str) -> None:
        data = {"branch": self.branches, "activity": self.activities, "record": self.records}[etype]
        self._path(etype).write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    def _coll(self, etype: str) -> List[Dict[str, Any]]:
        return {"branch": self.branches, "activity": self.activities, "record": self.records}[etype]

    # ---- validation --------------------------------------------------
    def _require(self, payload: Dict[str, Any], fields: List[str]) -> Optional[str]:
        for f in fields:
            if f not in payload or payload[f] in (None, ""):
                if f == "description" and f in payload:
                    continue
                return f"Missing required field: {f}"
        return None

    def _validate(self, action: str, etype: str, eid: str, payload: Dict[str, Any]) -> Optional[str]:
        if payload.get("id") != eid:
            return "Payload id does not match entity id"
        if etype == "branch":
            err = self._require(payload, ["id", "name", "accent_color", "icon_code_point"])
            if err:
                return err
            for b in self.branches:
                if b["id"] != eid and _norm(b.get("name")) == _norm(payload["name"]):
                    return f'A branch named "{payload["name"]}" already exists'
        elif etype == "activity":
            err = self._require(payload, ["id", "branch_id", "name", "accent_color", "icon_code_point"])
            if err:
                return err
            if not any(b["id"] == payload["branch_id"] for b in self.branches):
                return f"Branch '{payload['branch_id']}' does not exist"
            for a in self.activities:
                if (a["id"] != eid and a.get("branch_id") == payload["branch_id"]
                        and _norm(a.get("name")) == _norm(payload["name"])):
                    return f'Activity "{payload["name"]}" already exists in this branch'
            fields = payload.get("fields", [])
            if not isinstance(fields, list):
                return "fields must be a list"
            seen = set()
            for f in fields:
                if not isinstance(f, dict) or not f.get("id") or not f.get("name") or not f.get("type"):
                    return "Every field needs id, name and type"
                if f["id"] in seen:
                    return f"Duplicate field id '{f['id']}'"
                seen.add(f["id"])
            err = self._goal_error(payload, fields)
            if err:
                return err
        elif etype == "record":
            err = self._require(payload, ["id", "activity_id", "branch_id", "timestamp"])
            if err:
                return err
            act = next((a for a in self.activities if a["id"] == payload["activity_id"]), None)
            if act is None:
                return f"Activity '{payload['activity_id']}' does not exist"
            if act.get("branch_id") != payload["branch_id"]:
                return "Record branch does not match the activity's branch"
            values = payload.get("field_values", {})
            if not isinstance(values, dict):
                return "field_values must be an object"
            for f in act.get("fields", []):
                if f.get("required", True) and values.get(f["id"]) in (None, ""):
                    return f"Missing value for required field '{f['name']}'"
            if action == "create" and act.get("goal") is not None:
                gv = values.get(act.get("goal_field_id"))
                if not _is_num(gv):
                    return "Missing goal value"
                effective = payload["goal"] if payload.get("goal") is not None else act["goal"]
                if not _is_num(effective) or effective <= 0:
                    return "Goal must be greater than 0"
                base = act.get("base_xp", 10)
                if payload.get("xp_earned") != goal_xp(base, gv, effective):
                    return "Points do not match the goal"
        return None

    @staticmethod
    def _goal_error(a: Dict[str, Any], fields: List[Dict[str, Any]]) -> Optional[str]:
        goal, gfid = a.get("goal"), a.get("goal_field_id")
        if goal is None and gfid is None:
            return None
        if goal is None:
            return "Goal field needs a goal"
        if not _is_num(goal) or goal <= 0:
            return "Goal must be greater than 0"
        f = next((f for f in fields if f["id"] == gfid), None)
        if f is None:
            return "Goal needs a field to measure"
        if f["type"] not in NUMERIC_TYPES:
            return "Goal field must be a number or duration field"
        return None

    # ---- operations --------------------------------------------------
    def audit(self, action: str, etype: str, eid: str, payload: Dict[str, Any]) -> Dict[str, str]:
        if action not in ACTIONS:
            return self._rej(f"Unknown action: {action}")
        if etype not in FILES:
            return self._rej(f"Unknown entity type: {etype}")
        coll = self._coll(etype)
        idx = next((i for i, e in enumerate(coll) if e.get("id") == eid), -1)

        if action == "create":
            if idx >= 0:
                return self._rej(f'{etype.capitalize()} "{eid}" already exists')
        elif idx < 0:
            return self._rej(f'{etype.capitalize()} "{eid}" does not exist')

        if action == "delete":
            if etype == "branch":
                gone = {a["id"] for a in self.activities if a.get("branch_id") == eid}
                self.activities = [a for a in self.activities if a.get("branch_id") != eid]
                self.records = [r for r in self.records if r.get("branch_id") != eid and r.get("activity_id") not in gone]
                self.branches = [b for b in self.branches if b["id"] != eid]
                for t in FILES:
                    self._save(t)
            elif etype == "activity":
                self.activities = [a for a in self.activities if a["id"] != eid]
                self.records = [r for r in self.records if r.get("activity_id") != eid]
                self._save("activity")
                self._save("record")
            else:
                self.records = [r for r in self.records if r["id"] != eid]
                self._save("record")
            return {"status": "SUCCESS", "message": f"{etype.capitalize()} deleted"}

        err = self._validate(action, etype, eid, payload)
        if err:
            return self._rej(f"Validation failed: {err}")
        if action == "create":
            coll.append(payload)
        else:
            coll[idx] = payload
        self._save(etype)
        verb = "created" if action == "create" else "updated"
        return {"status": "SUCCESS", "message": f"{etype.capitalize()} {verb}"}

    @staticmethod
    def _rej(msg: str) -> Dict[str, str]:
        return {"status": "REJECTED", "message": msg}


def write_status(root: Path, op_id: str, result: Dict[str, str], etype: str, eid: str, action: str) -> Path:
    if not OP_ID_RE.match(op_id or ""):
        raise ValueError("Invalid operation id")
    d = Path(root) / "status"
    d.mkdir(parents=True, exist_ok=True)
    out = d / f"{op_id}.json"
    out.write_text(json.dumps({
        "operation_id": op_id,
        "status": result["status"],
        "message": result["message"],
        "action": action,
        "entity_type": etype,
        "entity_id": eid,
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }, indent=2) + "\n", encoding="utf-8")
    files = sorted(d.glob("*.json"), key=lambda p: p.stat().st_mtime)
    for old in files[:-MAX_STATUS_FILES]:
        old.unlink()
    return out


def main() -> int:
    env = os.environ
    op_id = env.get("RPG_OPERATION_ID", "")
    action = env.get("RPG_ACTION", "create")
    etype = env.get("RPG_ENTITY_TYPE", "")
    eid = env.get("RPG_ENTITY_ID", "")
    root = Path(env.get("RPG_ROOT", "."))
    try:
        payload = json.loads(env.get("RPG_PAYLOAD") or "{}")
        if not isinstance(payload, dict):
            raise ValueError("payload must be an object")
        result = EntityAuditor(str(root)).audit(action, etype, eid, payload)
    except Exception as exc:  # noqa: BLE001 - report every failure through the status file
        result = {"status": "FAILED", "message": f"Audit error: {exc}"}
    try:
        write_status(root, op_id, result, etype, eid, action)
    except ValueError as exc:
        print(f"::error::{exc}")
        return 1
    print(f"{result['status']}: {result['message']}")
    out = env.get("GITHUB_OUTPUT")
    if out:
        with open(out, "a", encoding="utf-8") as fh:
            fh.write(f"status={result['status']}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
