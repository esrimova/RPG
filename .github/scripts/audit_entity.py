#!/usr/bin/env python3
"""
Audit script for GitHub Actions workflow.
Validates entity creation requests against existing JSON data files.
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Dict, Any, Optional, List


class EntityAuditor:
    def __init__(self, repo_root: str = "."):
        self.repo_root = Path(repo_root)
        self.branches_file = self.repo_root / "branches.json"
        self.activities_file = self.repo_root / "activities.json"
        self.records_file = self.repo_root / "records.json"
        
        # Load existing data
        self.branches = self._load_json(self.branches_file)
        self.activities = self._load_json(self.activities_file)
        self.records = self._load_json(self.records_file)

    def _load_json(self, file_path: Path) -> List[Dict[str, Any]]:
        """Load JSON file, return empty list if not exists or invalid."""
        if not file_path.exists():
            return []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                if isinstance(data, list):
                    return data
                elif isinstance(data, dict) and 'data' in data:
                    return data['data']
                return []
        except (json.JSONDecodeError, IOError):
            return []

    def _save_json(self, file_path: Path, data: List[Dict[str, Any]]) -> None:
        """Save JSON file with pretty formatting."""
        file_path.parent.mkdir(parents=True, exist_ok=True)
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

    def _entity_exists(self, entity_type: str, entity_id: str) -> bool:
        """Check if entity already exists."""
        if entity_type == 'branch':
            return any(b.get('id') == entity_id for b in self.branches)
        elif entity_type == 'activity':
            return any(a.get('id') == entity_id for a in self.activities)
        elif entity_type == 'record':
            return any(r.get('id') == entity_id for r in self.records)
        return False

    def _validate_branch_payload(self, payload: Dict[str, Any]) -> Optional[str]:
        """Validate branch payload structure."""
        required_fields = ['id', 'name', 'description', 'accent_color', 'icon_code_point']
        for field in required_fields:
            if field not in payload:
                return f"Missing required field: {field}"
        return None

    def _validate_activity_payload(self, payload: Dict[str, Any]) -> Optional[str]:
        """Validate activity payload structure."""
        required_fields = ['id', 'branch_id', 'name', 'description', 'category', 'accent_color', 'icon_code_point']
        for field in required_fields:
            if field not in payload:
                return f"Missing required field: {field}"
        
        # Validate branch_id exists
        branch_id = payload.get('branch_id')
        if branch_id and not any(b.get('id') == branch_id for b in self.branches):
            return f"Referenced branch_id '{branch_id}' does not exist"
        
        return None

    def _validate_record_payload(self, payload: Dict[str, Any]) -> Optional[str]:
        """Validate record payload structure."""
        required_fields = ['id', 'activity_id', 'branch_id', 'timestamp', 'field_values', 'xp_earned']
        for field in required_fields:
            if field not in payload:
                return f"Missing required field: {field}"
        
        # Validate activity_id exists
        activity_id = payload.get('activity_id')
        if activity_id and not any(a.get('id') == activity_id for a in self.activities):
            return f"Referenced activity_id '{activity_id}' does not exist"
        
        # Validate branch_id exists
        branch_id = payload.get('branch_id')
        if branch_id and not any(b.get('id') == branch_id for b in self.branches):
            return f"Referenced branch_id '{branch_id}' does not exist"
        
        return None

    def audit(self, entity_type: str, entity_id: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Audit the entity creation request.
        Returns dict with 'status' (SUCCESS/REJECTED) and 'message'.
        """
        # Check if entity already exists
        if self._entity_exists(entity_type, entity_id):
            return {
                'status': 'REJECTED',
                'message': f'{entity_type.capitalize()} with id "{entity_id}" already exists',
                'should_commit': False
            }

        # Validate payload based on entity type
        validation_error = None
        if entity_type == 'branch':
            validation_error = self._validate_branch_payload(payload)
        elif entity_type == 'activity':
            validation_error = self._validate_activity_payload(payload)
        elif entity_type == 'record':
            validation_error = self._validate_record_payload(payload)
        else:
            return {
                'status': 'REJECTED',
                'message': f'Unknown entity type: {entity_type}',
                'should_commit': False
            }

        if validation_error:
            return {
                'status': 'REJECTED',
                'message': f'Validation failed: {validation_error}',
                'should_commit': False
            }

        # All checks passed - add entity to appropriate collection
        if entity_type == 'branch':
            self.branches.append(payload)
            self._save_json(self.branches_file, self.branches)
        elif entity_type == 'activity':
            self.activities.append(payload)
            self._save_json(self.activities_file, self.activities)
        elif entity_type == 'record':
            self.records.append(payload)
            self._save_json(self.records_file, self.records)

        return {
            'status': 'SUCCESS',
            'message': f'{entity_type.capitalize()} "{entity_id}" created successfully',
            'should_commit': True
        }


def parse_payload(payload_str: str) -> Dict[str, Any]:
    """Parse payload string, handling both JSON and escaped JSON."""
    # Try direct JSON parse first
    try:
        return json.loads(payload_str)
    except json.JSONDecodeError:
        pass
    
    # Try unescaping and parsing
    try:
        # Handle escaped quotes
        unescaped = payload_str.replace('\\"', '"').replace("\\'", "'")
        return json.loads(unescaped)
    except json.JSONDecodeError:
        pass
    
    # Return empty dict if all parsing fails
    return {}


def main():
    parser = argparse.ArgumentParser(description='Audit entity creation for RPG data')
    parser.add_argument('--event-type', required=True, help='Event type (repository_dispatch, workflow_dispatch)')
    parser.add_argument('--entity-type', required=True, choices=['branch', 'activity', 'record'], help='Entity type')
    parser.add_argument('--entity-id', required=True, help='Entity ID')
    parser.add_argument('--payload', required=True, help='JSON payload string')
    
    args = parser.parse_args()
    
    # Parse payload
    payload = parse_payload(args.payload)
    
    if not payload:
        print("::error::Failed to parse payload as JSON")
        print("status=REJECTED")
        print("message=Failed to parse payload as JSON")
        sys.exit(1)
    
    # Run audit
    auditor = EntityAuditor()
    result = auditor.audit(args.entity_type, args.entity_id, payload)
    
    # Output results for GitHub Actions
    print(f"status={result['status']}")
    print(f"message={result['message']}")
    print(f"should_commit={str(result['should_commit']).lower()}")
    
    # Exit with error code if rejected
    if result['status'] == 'REJECTED':
        sys.exit(1)


if __name__ == '__main__':
    main()