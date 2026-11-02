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
