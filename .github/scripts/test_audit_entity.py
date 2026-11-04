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
        data = json.loads((self.root / "game" / "status" / "op-1.json").read_text())
        self.assertEqual(data["operation_id"], "op-1")
        self.assertEqual(data["status"], "SUCCESS")

    def test_bad_operation_id_rejected(self):
        with self.assertRaises(ValueError):
            ae.write_status(self.root, "../evil", {"status": "SUCCESS", "message": ""}, "branch", "b1", "create")



def task(id_="t1", name="Cut wood", date="2026-03-02", done=None):
    t = {"id": id_, "name": name, "date": date}
    if done:
        t["done_at"] = done
    return t


def quest(id_="q1", name="Cabin", start="2026-03-01", end="2026-03-10", total=100,
          dist="manual", tasks=None, pattern=None):
    q = {
        "id": id_, "name": name, "description": "", "start_date": start, "end_date": end,
        "total_xp": total, "distribution": dist,
        "tasks": tasks if tasks is not None else [task()],
        "created_at": "2026-03-01T00:00:00",
    }
    if pattern is not None:
        q["pattern"] = pattern
    return q


class QuestAuditTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.a = ae.EntityAuditor(str(self.root))

    def tearDown(self):
        self.tmp.cleanup()

    def op(self, action, payload, eid=None, local_date="2026-03-05"):
        eid = eid if eid is not None else payload.get("id", "q1")
        return self.a.audit(action, "quest", eid, payload, local_date)

    def assertRejected(self, r, msg):
        self.assertEqual(r["status"], "REJECTED", r)
        self.assertIn(msg, r["message"])

    def test_create_and_persist(self):
        self.assertEqual(self.op("create", quest())["status"], "SUCCESS")
        self.assertEqual(len(ae.EntityAuditor(str(self.root)).quests), 1)
        self.assertTrue((self.root / "game" / "quests.json").exists())

    def test_create_duplicate_and_update_missing(self):
        self.op("create", quest())
        self.assertRejected(self.op("create", quest()), "already exists")
        self.assertRejected(self.op("update", quest("zz"), "zz"), "does not exist")

    def test_delete_always_ok_even_finished(self):
        self.op("create", quest(tasks=[task(done="2026-03-02T10:00:00")]))
        self.assertEqual(self.op("delete", {}, "q1", local_date="2027-01-01")["status"], "SUCCESS")
        self.assertEqual(self.a.quests, [])

    def test_update_completed_is_finished(self):
        self.op("create", quest(tasks=[task(done="2026-03-02T10:00:00")]))
        self.assertRejected(self.op("update", quest(name="New")), "Quest is finished")

    def test_update_failed_as_of_local_date(self):
        self.op("create", quest())
        self.assertRejected(self.op("update", quest(name="New"), local_date="2026-03-11"), "Quest is finished")
        self.assertEqual(self.op("update", quest(name="New"), local_date="2026-03-10")["status"], "SUCCESS")

    def test_last_task_on_end_date_pushed_later_accepted(self):
        self.op("create", quest())
        done = quest(tasks=[task(done="2026-03-10T20:00:00")])
        self.assertEqual(self.op("update", done, local_date="2026-03-10")["status"], "SUCCESS")

    def test_update_needs_local_date(self):
        self.op("create", quest())
        self.assertRejected(self.op("update", quest(name="N"), local_date=None), "local date")
        self.assertRejected(self.op("update", quest(name="N"), local_date="soon"), "local date")

    def test_distribution_must_be_auto_or_manual(self):
        self.assertRejected(self.op("create", quest(dist="random")), "Distribution must be auto or manual")

    def test_malformed_payloads_invalid_quest(self):
        for key, bad in [("total_xp", "100"), ("total_xp", True), ("tasks", None), ("tasks", "x"),
                         ("name", 5), ("start_date", 20260301), ("tasks", [5]), ("tasks", [{"id": "t"}])]:
            q = quest()
            q[key] = bad
            self.assertRejected(self.op("create", q), "Invalid quest")
        q = quest()
        del q["tasks"]
        self.assertRejected(self.op("create", q), "Invalid quest")
        q = quest()
        q["tasks"][0]["done_at"] = "not a date"
        self.assertRejected(self.op("create", q), "Invalid quest")

    def test_field_rules(self):
        self.assertRejected(self.op("create", quest(name="  ")), "Quest name is required")
        self.assertRejected(self.op("create", quest(total=-1)), "Quest points cannot be negative")
        self.assertRejected(self.op("create", quest(start="2026-3-1")), "Quest dates must be YYYY-MM-DD")
        self.assertRejected(self.op("create", quest(end="2026-02-30")), "Quest dates must be YYYY-MM-DD")
        self.assertRejected(self.op("create", quest(start="2026-03-11")), "Start date must not be after end date")

    def test_quest_needs_id(self):
        self.assertRejected(self.op("create", quest(id_=""), ""), "Quest needs an id")

    def test_auto_pattern_rules(self):
        self.assertRejected(self.op("create", quest(dist="auto")), "Automatic quest needs a pattern")
        self.assertRejected(self.op("create", quest(dist="auto", pattern={"type": "every_n_days", "n": 0})),
                            "Pattern needs n greater than 0")
        self.assertRejected(self.op("create", quest(dist="auto", pattern={"type": "weekdays", "days": []})),
                            "Pattern needs weekdays 1-7")
        self.assertRejected(self.op("create", quest(dist="auto", pattern={"type": "weekdays", "days": [8]})),
                            "Pattern needs weekdays 1-7")
        self.assertRejected(self.op("create", quest(dist="auto", pattern={"type": "monthly"})), "Invalid quest")
        ok = quest(dist="auto", pattern={"type": "weekdays", "days": [1, 3]})
        self.assertEqual(self.op("create", ok)["status"], "SUCCESS")

    def test_task_rules(self):
        self.assertRejected(self.op("create", quest(tasks=[task("t1"), task("t1")])), "Task ids must be unique")
        self.assertRejected(self.op("create", quest(tasks=[task("")])), "Task ids must be unique")
        self.assertRejected(self.op("create", quest(tasks=[task(name=" ")])), "Task name is required")
        self.assertRejected(self.op("create", quest(tasks=[task(date="2026-13-01")])), "Task dates must be YYYY-MM-DD")
        self.assertRejected(self.op("create", quest(tasks=[task(date="2026-03-11")])), "Task date is outside the quest range")
        self.assertRejected(self.op("create", quest(tasks=[task(date="2026-02-28")])), "Task date is outside the quest range")

    def test_unique_name(self):
        self.op("create", quest())
        self.assertRejected(self.op("create", quest("q2", " cabin ")), 'A quest named " cabin " already exists')

    def test_zero_tasks_allowed_and_active(self):
        self.assertEqual(self.op("create", quest(tasks=[]))["status"], "SUCCESS")
        self.assertEqual(self.op("update", quest(name="Hut", tasks=[]))["status"], "SUCCESS")

    def test_removing_tasks_cannot_complete(self):
        both = quest(tasks=[task("t1", done="2026-03-02T10:00:00"), task("t2", date="2026-03-04")])
        self.op("create", both)
        only_done = quest(tasks=[task("t1", done="2026-03-02T10:00:00")])
        self.assertRejected(self.op("update", only_done), "Cannot complete a quest by removing tasks")
        self.assertEqual(self.op("update", quest(tasks=[task("t2", date="2026-03-04")]))["status"], "SUCCESS")
        self.assertEqual(self.op("update", quest(tasks=[]))["status"], "SUCCESS")

    def test_quest_op_keeps_other_collections(self):
        self.a.audit("create", "branch", "b1", branch())
        self.op("create", quest())
        again = ae.EntityAuditor(str(self.root))
        self.assertEqual((len(again.branches), len(again.quests)), (1, 1))


class BatchTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    @staticmethod
    def op(oid, action, etype, eid, payload, local_date="2026-03-05"):
        return {"operation_id": oid, "action": action, "entity_type": etype, "entity_id": eid,
                "payload": payload, "local_date": local_date}

    def test_max_status_files_exceeds_batch(self):
        self.assertGreaterEqual(ae.MAX_STATUS_FILES, 500)

    def test_files_mapping_has_quest(self):
        self.assertEqual(ae.FILES["quest"], "quests.json")

    def test_three_ops_three_status_files_one_state(self):
        ops = [
            self.op("o1", "create", "branch", "b1", branch()),
            self.op("o2", "create", "activity", "a1", activity()),
            self.op("o3", "create", "record", "r1", record()),
        ]
        res = ae.run_batch(self.root, ops)
        self.assertEqual([r["status"] for r in res], ["SUCCESS"] * 3)
        self.assertEqual(len(list((self.root / "game" / "status").glob("*.json"))), 3)
        a = ae.EntityAuditor(str(self.root))
        self.assertEqual((len(a.branches), len(a.activities), len(a.records)), (1, 1, 1))

    def test_rejected_create_rejects_dependents_but_not_independent(self):
        ops = [
            self.op("o1", "create", "branch", "b1", {"id": "b1", "name": ""}),
            self.op("o2", "create", "activity", "a1", activity()),
            self.op("o3", "create", "quest", "q1", quest()),
        ]
        res = ae.run_batch(self.root, ops)
        self.assertEqual([r["status"] for r in res], ["REJECTED", "REJECTED", "SUCCESS"])
        a = ae.EntityAuditor(str(self.root))
        self.assertEqual((a.branches, a.activities, len(a.quests)), ([], [], 1))
        self.assertEqual(len(list((self.root / "game" / "status").glob("*.json"))), 3)

    def test_each_op_sees_state_left_by_previous(self):
        ops = [
            self.op("o1", "create", "quest", "q1", quest()),
            self.op("o2", "update", "quest", "q1", quest(name="Hut")),
            self.op("o3", "delete", "quest", "q1", {}),
        ]
        self.assertEqual([r["status"] for r in ae.run_batch(self.root, ops)], ["SUCCESS"] * 3)

    def test_second_run_is_idempotent(self):
        ops = [
            self.op("o1", "create", "branch", "b1", branch()),
            self.op("o2", "create", "branch", "b2", {"id": "b2"}),
        ]
        first = ae.run_batch(self.root, ops)
        second = ae.run_batch(self.root, ops)
        self.assertEqual([r["status"] for r in second], [r["status"] for r in first])
        self.assertEqual(second[0]["status"], "SUCCESS")
        self.assertEqual(second[1]["status"], "REJECTED")
        self.assertEqual(second[1]["message"], first[1]["message"])
        self.assertEqual(len(ae.EntityAuditor(str(self.root)).branches), 1)

    def test_resend_of_applied_op_not_reapplied(self):
        ae.run_batch(self.root, [self.op("o1", "create", "quest", "q1", quest())])
        ae.run_batch(self.root, [self.op("o2", "delete", "quest", "q1", {})])
        res = ae.run_batch(self.root, [self.op("o1", "create", "quest", "q1", quest())])
        self.assertEqual(res[0]["status"], "SUCCESS")
        self.assertEqual(ae.EntityAuditor(str(self.root)).quests, [])

    def test_bad_operation_id_does_not_stop_rest(self):
        ops = [
            self.op("../evil", "create", "branch", "b1", branch()),
            self.op("o2", "create", "branch", "b2", branch("b2", "Mind")),
        ]
        res = ae.run_batch(self.root, ops)
        self.assertEqual(res[0]["status"], "REJECTED")
        self.assertEqual(res[1]["status"], "SUCCESS")

    def test_non_dict_payload_fails_only_that_op(self):
        ops = [
            self.op("o1", "create", "branch", "b1", "nope"),
            self.op("o2", "create", "branch", "b2", branch("b2", "Mind")),
        ]
        res = ae.run_batch(self.root, ops)
        self.assertEqual([r["status"] for r in res], ["FAILED", "SUCCESS"])

    def test_main_batch_from_env(self):
        ops = [self.op("o1", "create", "quest", "q1", quest())]
        old = dict(os.environ)
        try:
            os.environ["RPG_ROOT"] = str(self.root)
            os.environ["RPG_OPERATIONS"] = json.dumps(ops)
            self.assertEqual(ae.main(), 0)
        finally:
            os.environ.clear()
            os.environ.update(old)
        self.assertEqual(len(ae.EntityAuditor(str(self.root)).quests), 1)

    def test_main_single_op_env_still_works(self):
        old = dict(os.environ)
        try:
            os.environ.pop("RPG_OPERATIONS", None)
            os.environ.update({"RPG_ROOT": str(self.root), "RPG_OPERATION_ID": "s1", "RPG_ACTION": "create",
                               "RPG_ENTITY_TYPE": "branch", "RPG_ENTITY_ID": "b1",
                               "RPG_PAYLOAD": json.dumps(branch())})
            self.assertEqual(ae.main(), 0)
        finally:
            os.environ.clear()
            os.environ.update(old)
        data = json.loads((self.root / "game" / "status" / "s1.json").read_text())
        self.assertEqual(data["status"], "SUCCESS")


if __name__ == "__main__":
    unittest.main()


class GameFolderTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def auditor(self):
        return ae.EntityAuditor(str(self.root))

    def test_data_is_written_inside_game_folder(self):
        self.auditor().audit("create", "branch", "b1", branch())
        self.assertTrue((self.root / "game" / "branches.json").exists())
        self.assertFalse((self.root / "branches.json").exists())

    def test_legacy_root_files_are_read_then_moved(self):
        (self.root / "branches.json").write_text(json.dumps([branch()]), encoding="utf-8")
        a = self.auditor()
        self.assertEqual(len(a.branches), 1)
        self.assertEqual(a.audit("create", "branch", "b2", branch("b2", "Mind"))["status"], "SUCCESS")
        self.assertFalse((self.root / "branches.json").exists())
        self.assertEqual(len(json.loads((self.root / "game" / "branches.json").read_text())), 2)


class LevelCostsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.a = ae.EntityAuditor(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def op(self, costs):
        b = branch()
        if costs is not ...:
            b["level_costs"] = costs
        return self.a.audit("create", "branch", "b1", b)["status"]

    def test_valid_and_absent(self):
        self.assertEqual(self.op(...), "SUCCESS")

    def test_valid_list(self):
        self.assertEqual(self.op([500, 750, 1000]), "SUCCESS")

    def test_invalid_lists(self):
        for bad in ([], [0], [-5], [10.5], ["500"], [True], "500", [500] * 201):
            self.setUp()
            self.assertEqual(self.op(bad), "REJECTED", bad)


class StatTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.a = ae.EntityAuditor(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def stat(self, id_="s1", values=None, ts="2026-11-04T08:30:00"):
        return {"id": id_, "timestamp": ts, "values": values if values is not None else {"weight": 80.5, "fat": 18}}

    def op(self, action, payload, eid="s1"):
        return self.a.audit(action, "stat", eid, payload)

    def test_create_persist_and_delete(self):
        self.assertEqual(self.op("create", self.stat())["status"], "SUCCESS")
        self.assertTrue((self.root / "game" / "stats.json").exists())
        self.assertEqual(len(ae.EntityAuditor(self.tmp.name).stats), 1)
        self.assertEqual(self.op("delete", {"id": "s1"})["status"], "SUCCESS")
        self.assertEqual(ae.EntityAuditor(self.tmp.name).stats, [])

    def test_duplicate_and_missing(self):
        self.op("create", self.stat())
        self.assertEqual(self.op("create", self.stat())["status"], "REJECTED")
        self.assertEqual(self.op("delete", {"id": "zz"}, "zz")["status"], "REJECTED")

    def test_update_not_allowed(self):
        self.op("create", self.stat())
        self.assertEqual(self.op("update", self.stat(values={"weight": 70}))["status"], "REJECTED")

    def test_bad_entries_rejected(self):
        bad = [
            self.stat(values={}),
            self.stat(values={"height": 180}),
            self.stat(values={"weight": -1}),
            self.stat(values={"weight": "80"}),
            self.stat(values={"weight": True}),
            self.stat(values={"fat": 101}),
            self.stat(ts="not a date"),
        ]
        for i, p in enumerate(bad):
            r = self.op("create", p, p["id"])
            self.assertEqual(r["status"], "REJECTED", p)

    def test_all_nine_stats(self):
        v = {"weight": 80, "fat": 18, "wat": 55, "msl": 40, "bon": 3.1, "calo": 1800, "pxfat": 12, "protein": 17, "bmi": 24.2}
        self.assertEqual(self.op("create", self.stat(values=v))["status"], "SUCCESS")
