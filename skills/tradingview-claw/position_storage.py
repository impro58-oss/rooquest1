"""
position_storage.py — Local JSON position store for TradingView-Claw
Positions stored at ~/.openclaw/tvclaw/positions.json
"""
import json
import os
from pathlib import Path
from typing import Optional


STORAGE_PATH = Path.home() / ".openclaw" / "tvclaw" / "positions.json"


class PositionStorage:
    def __init__(self, path: Optional[Path] = None):
        self.path = path or STORAGE_PATH
        self.path.parent.mkdir(parents=True, exist_ok=True)

    def _load(self) -> list[dict]:
        if not self.path.exists():
            return []
        with open(self.path) as f:
            return json.load(f)

    def _save(self, positions: list[dict]):
        with open(self.path, "w") as f:
            json.dump(positions, f, indent=2)

    def get_all_positions(self) -> list[dict]:
        return [p for p in self._load() if not p.get("closed")]

    def get_position(self, position_id: str) -> Optional[dict]:
        for p in self._load():
            if p["id"].startswith(position_id):
                return p
        return None

    def get_positions_for_symbol(self, symbol: str) -> list[dict]:
        return [p for p in self.get_all_positions() if p["symbol"] == symbol]

    def add_position(self, position: dict):
        positions = self._load()
        positions.append(position)
        self._save(positions)

    def close_position(self, position_id: str):
        positions = self._load()
        for p in positions:
            if p["id"] == position_id:
                p["closed"] = True
        self._save(positions)
