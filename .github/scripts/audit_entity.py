#!/usr/bin/env python3
"""Audit + apply one data operation (create / update / delete) for the RPG repo.

All inputs arrive through environment variables (never interpolated into a shell
command):

  RPG_ACTION, RPG_ENTITY_TYPE, RPG_ENTITY_ID, RPG_OPERATION_ID, RPG_PAYLOAD (JSON),
  RPG_LOCAL_DATE (YYYY-MM-DD, the device's calendar date)

or, for a batch, RPG_OPERATIONS: a JSON array of
{operation_id, action, entity_type, entity_id, payload, local_date}. Operations run in
order, each against the state left by the previous one; one bad operation never stops
the rest, and an operation_id that already has a status file is skipped (its stored
status is reported), so a resend can never apply a change twice.

Data lives in branches.json / activities.json / records.json / quests.json. The outcome of every
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
MAX_STATUS_FILES = 500
ACTIONS = ("create", "update", "delete")
FILES = {"branch": "branches.json", "activity": "activities.json", "record": "records.json",
         "quest": "quests.json"}


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


_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def valid_date(d: Any) -> bool:
    """Strict YYYY-MM-DD that is also a real calendar date."""
    if not isinstance(d, str) or not _DATE_RE.match(d):
        return False
    try:
        datetime.strptime(d, "%Y-%m-%d")
    except ValueError:
        return False
    return True


def _is_str(v: Any) -> bool:
    return isinstance(v, str)


def _parses_iso(v: Any) -> bool:
    if not _is_str(v):
        return False
    try:
        datetime.fromisoformat(v.replace("Z", "+00:00"))
    except ValueError:
        return False
    return True


def quest_shape_ok(q: Dict[str, Any]) -> bool:
    """Mirrors Quest.fromJson: the payload must parse, else 'Invalid quest'.
    Stricter than Dart on one point: tasks must be present (Dart defaults to [])."""
    if not (_is_str(q.get("id")) and _is_str(q.get("name"))
            and _is_str(q.get("start_date")) and _is_str(q.get("end_date"))
            and _is_num(q.get("total_xp"))):
        return False
    if q.get("description") is not None and not _is_str(q["description"]):
        return False
    if q.get("created_at") is not None and not _is_str(q["created_at"]):
        return False
    p = q.get("pattern")
    if p is not None:
        if not isinstance(p, dict):
            return False
        if p.get("type") == "every_n_days":
            if not _is_num(p.get("n")):
                return False
        elif p.get("type") == "weekdays":
            if not isinstance(p.get("days"), list) or not all(_is_num(d) for d in p["days"]):
                return False
        else:
            return False
    tasks = q.get("tasks")
    if not isinstance(tasks, list):
        return False
    for t in tasks:
        if not (isinstance(t, dict) and _is_str(t.get("id")) and _is_str(t.get("name"))
                and _is_str(t.get("date"))):
            return False
        if t.get("done_at") is not None and not _parses_iso(t["done_at"]):
            return False
    return True


def quest_status(q: Dict[str, Any], today: str) -> str:
    """completed (>=1 task, all checked) / failed (today > end_date) / active.

    Must match questStatus in lib/src/domain/quests.dart."""
    tasks = q.get("tasks", [])
    if tasks and all(t.get("done_at") is not None for t in tasks):
        return "completed"
    if today > q["end_date"]:
        return "failed"
    return "active"


def quest_error(q: Dict[str, Any]) -> Optional[str]:
    """Mirrors _questError in lib/src/domain/apply.dart (same messages)."""
    if not q["id"]:
        return "Quest needs an id"
    if not q["name"].strip():
        return "Quest name is required"
    if int(q["total_xp"]) < 0:
        return "Quest points cannot be negative"
    if not valid_date(q["start_date"]) or not valid_date(q["end_date"]):
        return "Quest dates must be YYYY-MM-DD"
    if q["start_date"] > q["end_date"]:
        return "Start date must not be after end date"
    if q.get("distribution") == "auto":
        p = q.get("pattern")
        if p is None:
            return "Automatic quest needs a pattern"
        if p["type"] == "every_n_days" and int(p["n"]) <= 0:
            return "Pattern needs n greater than 0"
        if p["type"] == "weekdays":
            days = [int(d) for d in p["days"]]
            if not days or any(d < 1 or d > 7 for d in days):
                return "Pattern needs weekdays 1-7"
    ids = set()
    for t in q["tasks"]:
        if not t["id"] or t["id"] in ids:
            return "Task ids must be unique"
        ids.add(t["id"])
        if not t["name"].strip():
            return "Task name is required"
        if not valid_date(t["date"]):
            return "Task dates must be YYYY-MM-DD"
        if t["date"] < q["start_date"] or t["date"] > q["end_date"]:
            return "Task date is outside the quest range"
    return None


class EntityAuditor:
    def __init__(self, repo_root: str = "."):
        self.root = Path(repo_root)
        self.branches = self._load("branch")
        self.activities = self._load("activity")
        self.records = self._load("record")
        self.quests = self._load("quest")

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
        data = self._coll(etype)
        self._path(etype).write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    def _coll(self, etype: str) -> List[Dict[str, Any]]:
        return {"branch": self.branches, "activity": self.activities,
                "record": self.records, "quest": self.quests}[etype]

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
        elif etype == "quest":
            return self._validate_quest(eid, payload)
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

    def _validate_quest(self, eid: str, q: Dict[str, Any]) -> Optional[str]:
        if q.get("distribution") not in ("auto", "manual"):
            return "Distribution must be auto or manual"
        if not quest_shape_ok(q):
            return "Invalid quest"
        err = quest_error(q)
        if err:
            return err
        if any(o["id"] != q["id"] and _norm(o.get("name")) == _norm(q["name"]) for o in self.quests):
            return f'A quest named "{q["name"]}" already exists'
        old = next((o for o in self.quests if o["id"] == eid), None)
        if old is not None:
            kept = {t["id"] for t in q["tasks"]}
            removed = any(t["id"] not in kept for t in old.get("tasks", []))
            if removed and q["tasks"] and all(t.get("done_at") is not None for t in q["tasks"]):
                return "Cannot complete a quest by removing tasks"
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
    def audit(self, action: str, etype: str, eid: str, payload: Dict[str, Any],
              local_date: Optional[str] = None) -> Dict[str, str]:
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
            elif etype == "quest":
                self.quests = [q for q in self.quests if q["id"] != eid]
                self._save("quest")
            else:
                self.records = [r for r in self.records if r["id"] != eid]
                self._save("record")
            return {"status": "SUCCESS", "message": f"{etype.capitalize()} deleted"}

        if etype == "quest" and action == "update":
            # Frozen quests (completed, or failed as of the operation's own date)
            # accept only delete. The runner clock is never used.
            if not valid_date(local_date):
                return self._rej("Quest update needs a valid local date")
            if quest_status(coll[idx], local_date) != "active":
                return self._rej("Quest is finished")
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


def run_batch(root: Any, operations: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Apply operations in order. Each is validated against the state left by the
    previous one; one bad operation never stops the rest. An operation_id that
    already has a status file is skipped and its stored status returned."""
    root = Path(root)
    results: List[Dict[str, Any]] = []
    auditor: Optional[EntityAuditor] = None
    load_error: Optional[str] = None
    try:
        auditor = EntityAuditor(str(root))
    except Exception as exc:  # noqa: BLE001
        load_error = f"Audit error: {exc}"
    for op in operations:
        op = op if isinstance(op, dict) else {}
        op_id = op.get("operation_id") or ""
        action = op.get("action") or ""
        etype = op.get("entity_type") or ""
        eid = op.get("entity_id") or ""
        if not isinstance(op_id, str) or not OP_ID_RE.match(op_id):
            results.append({"operation_id": str(op_id), "status": "REJECTED",
                            "message": "Invalid operation id", "skipped": False})
            continue
        stored = root / "status" / f"{op_id}.json"
        if stored.exists():
            try:
                prev = json.loads(stored.read_text(encoding="utf-8"))
                results.append({"operation_id": op_id, "status": prev["status"],
                                "message": prev.get("message", ""), "skipped": True})
                continue
            except (ValueError, KeyError, OSError):
                pass  # unreadable status file: treat as not done and re-run
        try:
            payload = op.get("payload")
            if payload is None:
                payload = {}
            if not isinstance(payload, dict):
                raise ValueError("payload must be an object")
            if auditor is None:
                raise RuntimeError(load_error or "repository not readable")
            result = auditor.audit(action, etype, eid, payload, op.get("local_date"))
        except Exception as exc:  # noqa: BLE001 - report every failure through the status file
            result = {"status": "FAILED", "message": f"Audit error: {exc}"}
        write_status(root, op_id, result, etype, eid, action)
        results.append({"operation_id": op_id, "status": result["status"],
                        "message": result["message"], "skipped": False})
    return results


def main() -> int:
    env = os.environ
    root = Path(env.get("RPG_ROOT", "."))
    raw = env.get("RPG_OPERATIONS")
    if raw:
        try:
            ops = json.loads(raw)
            if not isinstance(ops, list):
                raise ValueError("RPG_OPERATIONS must be a JSON array")
        except ValueError as exc:
            print(f"::error::{exc}")
            return 1
    else:
        try:
            payload: Any = json.loads(env.get("RPG_PAYLOAD") or "{}")
        except ValueError:
            payload = "invalid"  # becomes a FAILED status for this operation
        ops = [{
            "operation_id": env.get("RPG_OPERATION_ID", ""),
            "action": env.get("RPG_ACTION", "create"),
            "entity_type": env.get("RPG_ENTITY_TYPE", ""),
            "entity_id": env.get("RPG_ENTITY_ID", ""),
            "payload": payload,
            "local_date": env.get("RPG_LOCAL_DATE") or None,
        }]
    results = run_batch(root, ops)
    for r in results:
        tag = " (already processed)" if r["skipped"] else ""
        print(f"{r['operation_id']}: {r['status']}: {r['message']}{tag}")
    bad_id = [r for r in results if r["message"] == "Invalid operation id"]
    for r in bad_id:
        print(f"::error::Invalid operation id: {r['operation_id']}")
    counts: Dict[str, int] = {}
    for r in results:
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    if len(results) == 1:
        status = results[0]["status"]
    else:
        status = "SUCCESS" if set(counts) <= {"SUCCESS"} else "MIXED"
    summary = ", ".join(f"{n} {k.lower()}" for k, n in sorted(counts.items())) or "no operations"
    out = env.get("GITHUB_OUTPUT")
    if out:
        with open(out, "a", encoding="utf-8") as fh:
            fh.write(f"status={status}\nsummary={summary}\ncount={len(results)}\n")
    return 1 if len(results) == 1 and bad_id else 0


if __name__ == "__main__":
    sys.exit(main())
