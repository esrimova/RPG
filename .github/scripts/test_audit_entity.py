import json
import os
import tempfile
import unittest
from pathlib import Path

import audit_entity as ae


def branch(id_="b1", name="Physical"):
    return {"id": id_, "name": name, "description": "d", "accent_color": 1, "icon_code_point": 2}


def activity(id_="a1", branch_id="b1", name="Push-ups", fields=None):
    return {
        "id": id_, "branch_id": branch_id, "name": name, "description": "",
        "category": "general", "accent_color": 1, "icon_code_point": 2,
        "fields": fields if fields is not None else [
            {"id": "reps", "name": "Reps", "type": "integer", "required": True}
        ],
    }


def record(id_="r1", activity_id="a1", branch_id="b1", values=None):
    return {
        "id": id_, "activity_id": activity_id, "branch_id": branch_id,
        "timestamp": "2026-01-01T00:00:00", "field_values": values if values is not None else {"reps": 10},
        "xp_earned": 45,
    }


class AuditTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.a = ae.EntityAuditor(str(self.root))

    def tearDown(self):
        self.tmp.cleanup()

    def run_op(self, action, etype, eid, payload):
        return self.a.audit(action, etype, eid, payload)

    def test_empty_repo_starts_empty(self):
        self.assertEqual(self.a.branches, [])

    def test_create_branch_persists(self):
        r = self.run_op("create", "branch", "b1", branch())
        self.assertEqual(r["status"], "SUCCESS")
        again = ae.EntityAuditor(str(self.root))
        self.assertEqual(len(again.branches), 1)

    def test_duplicate_branch_rejected(self):
        self.run_op("create", "branch", "b1", branch())
        r = self.run_op("create", "branch", "b1", branch())
        self.assertEqual(r["status"], "REJECTED")

    def test_duplicate_branch_name_rejected(self):
        self.run_op("create", "branch", "b1", branch())
        r = self.run_op("create", "branch", "b2", branch("b2", " physical "))
        self.assertEqual(r["status"], "REJECTED")

    def test_activity_needs_branch(self):
        r = self.run_op("create", "activity", "a1", activity())
        self.assertEqual(r["status"], "REJECTED")

    def test_activity_duplicate_name_in_branch_rejected(self):
        self.run_op("create", "branch", "b1", branch())
        self.run_op("create", "activity", "a1", activity())
        r = self.run_op("create", "activity", "a2", activity("a2"))
        self.assertEqual(r["status"], "REJECTED")

    def test_record_validates_required_field(self):
        self.run_op("create", "branch", "b1", branch())
        self.run_op("create", "activity", "a1", activity())
        r = self.run_op("create", "record", "r1", record(values={}))
        self.assertEqual(r["status"], "REJECTED")
        r = self.run_op("create", "record", "r1", record())
        self.assertEqual(r["status"], "SUCCESS")

    # ---- goals -------------------------------------------------------
    GOAL_FIELDS = [{"id": "km", "name": "Km", "type": "number", "required": True}]

    def goal_activity(self, **extra):
        a = activity(fields=list(self.GOAL_FIELDS))
        a.update({"base_xp": 10, "goal": 5, "goal_field_id": "km"})
        a.update(extra)
        return a

    def goal_record(self, value, xp, **extra):
        r = record(values={"km": value})
        r["xp_earned"] = xp
        r.update(extra)
        return r

    def setup_goal(self):
        self.run_op("create", "branch", "b1", branch())
        self.assertEqual(self.run_op("create", "activity", "a1", self.goal_activity())["status"], "SUCCESS")

    def test_goal_xp_rounding(self):
        self.assertEqual(ae.goal_xp(10, 3, 4), 8)    # 7.5 -> 8
        self.assertEqual(ae.goal_xp(10, 0, 4), 0)
        self.assertEqual(ae.goal_xp(10, -2, 4), 0)
        self.assertEqual(ae.goal_xp(10, 10, 5), 20)

    def test_goal_without_goal_field_rejected(self):
        self.run_op("create", "branch", "b1", branch())
        a = self.goal_activity()
        del a["goal_field_id"]
        self.assertEqual(self.run_op("create", "activity", "a1", a)["status"], "REJECTED")

    def test_goal_field_without_goal_rejected(self):
        self.run_op("create", "branch", "b1", branch())
        a = self.goal_activity()
        del a["goal"]
        self.assertEqual(self.run_op("create", "activity", "a1", a)["status"], "REJECTED")

    def test_goal_field_unknown_rejected(self):
        self.run_op("create", "branch", "b1", branch())
        r = self.run_op("create", "activity", "a1", self.goal_activity(goal_field_id="nope"))
        self.assertEqual(r["status"], "REJECTED")

    def test_non_numeric_goal_field_rejected(self):
        self.run_op("create", "branch", "b1", branch())
        for t in ("text", "yesno", "scale"):
            a = self.goal_activity(fields=[{"id": "km", "name": "Km", "type": t, "required": True}])
            self.assertEqual(self.run_op("create", "activity", "a1", a)["status"], "REJECTED", t)

    def test_duration_goal_field_accepted(self):
        self.run_op("create", "branch", "b1", branch())
        a = self.goal_activity(fields=[{"id": "km", "name": "Km", "type": "duration", "required": True}])
        self.assertEqual(self.run_op("create", "activity", "a1", a)["status"], "SUCCESS")

    def test_goal_not_positive_rejected(self):
        self.run_op("create", "branch", "b1", branch())
        for g in (0, -1, "5", True):
            r = self.run_op("create", "activity", "a1", self.goal_activity(goal=g))
            self.assertEqual(r["status"], "REJECTED", g)

    def test_record_wrong_xp_rejected_correct_accepted(self):
        self.setup_goal()
        self.assertEqual(self.run_op("create", "record", "r1", self.goal_record(3, 45))["status"], "REJECTED")
        self.assertEqual(self.run_op("create", "record", "r1", self.goal_record(3, 6))["status"], "SUCCESS")

    def test_record_zero_value_requires_zero_xp(self):
        self.setup_goal()
        self.assertEqual(self.run_op("create", "record", "r1", self.goal_record(0, 5))["status"], "REJECTED")
        self.assertEqual(self.run_op("create", "record", "r1", self.goal_record(0, 0))["status"], "SUCCESS")

    def test_record_missing_or_non_numeric_goal_value_rejected(self):
        self.setup_goal()
        self.assertEqual(self.run_op("create", "record", "r1", self.goal_record("3", 6))["status"], "REJECTED")
        self.assertEqual(self.run_op("create", "record", "r2", self.goal_record(True, 2))["status"], "REJECTED")
        r = record(values={})
        self.assertEqual(self.run_op("create", "record", "r1", r)["status"], "REJECTED")
        a = self.goal_activity()
        a["fields"][0]["required"] = False
        self.run_op("update", "activity", "a1", a)
        self.assertEqual(self.run_op("create", "record", "r3", r)["status"], "REJECTED")

    def test_record_goal_override_used(self):
        self.setup_goal()
        self.assertEqual(self.run_op("create", "record", "r1", self.goal_record(3, 6, goal=10))["status"], "REJECTED")
        self.assertEqual(self.run_op("create", "record", "r1", self.goal_record(3, 3, goal=10))["status"], "SUCCESS")

    def test_record_goal_not_positive_rejected(self):
        self.setup_goal()
        for g in (0, -3):
            r = self.run_op("create", "record", "r1", self.goal_record(3, 0, goal=g))
            self.assertEqual(r["status"], "REJECTED", g)

    def test_record_goal_ignored_without_activity_goal(self):
        self.run_op("create", "branch", "b1", branch())
        self.run_op("create", "activity", "a1", activity())
        r = record()
        r["goal"] = 0
        self.assertEqual(self.run_op("create", "record", "r1", r)["status"], "SUCCESS")

    def test_activity_goal_update_leaves_records_untouched(self):
        self.setup_goal()
        self.run_op("create", "record", "r1", self.goal_record(3, 6))
        r = self.run_op("update", "activity", "a1", self.goal_activity(goal=10))
        self.assertEqual(r["status"], "SUCCESS")
        stored = ae.EntityAuditor(str(self.root)).records
        self.assertEqual(stored[0]["xp_earned"], 6)

    def test_update_requires_existing(self):
        r = self.run_op("update", "branch", "zzz", branch("zzz"))
        self.assertEqual(r["status"], "REJECTED")
        self.run_op("create", "branch", "b1", branch())
        changed = branch(name="Renamed")
        r = self.run_op("update", "branch", "b1", changed)
        self.assertEqual(r["status"], "SUCCESS")
        self.assertEqual(ae.EntityAuditor(str(self.root)).branches[0]["name"], "Renamed")

    def test_delete_branch_cascades(self):
        self.run_op("create", "branch", "b1", branch())
        self.run_op("create", "activity", "a1", activity())
        self.run_op("create", "record", "r1", record())
        r = self.run_op("delete", "branch", "b1", {})
        self.assertEqual(r["status"], "SUCCESS")
        again = ae.EntityAuditor(str(self.root))
        self.assertEqual((again.branches, again.activities, again.records), ([], [], []))

    def test_unknown_action_rejected(self):
        self.assertEqual(self.run_op("explode", "branch", "b1", branch())["status"], "REJECTED")

    def test_id_mismatch_rejected(self):
        self.assertEqual(self.run_op("create", "branch", "other", branch())["status"], "REJECTED")

    def test_status_file_written_per_operation(self):
        ae.write_status(self.root, "op-1", {"status": "SUCCESS", "message": "ok"}, "branch", "b1", "create")
        data = json.loads((self.root / "status" / "op-1.json").read_text())
        self.assertEqual(data["operation_id"], "op-1")
        self.assertEqual(data["status"], "SUCCESS")

    def test_bad_operation_id_rejected(self):
        with self.assertRaises(ValueError):
            ae.write_status(self.root, "../evil", {"status": "SUCCESS", "message": ""}, "branch", "b1", "create")


if __name__ == "__main__":
    unittest.main()
