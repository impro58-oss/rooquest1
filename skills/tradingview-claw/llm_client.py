"""
llm_client.py — OpenRouter LLM client for TradingView-Claw
"""
import os
import httpx
from typing import Optional


class LLMClient:
    BASE_URL = "https://openrouter.ai/api/v1/chat/completions"
    DEFAULT_MODEL = "nvidia/nemotron-nano-9b-v2:free"

    def __init__(self, model: Optional[str] = None, api_key: Optional[str] = None):
        self.model = model or self.DEFAULT_MODEL
        self.api_key = api_key or os.environ.get("OPENROUTER_API_KEY", "")
        if not self.api_key:
            raise EnvironmentError(
                "OPENROUTER_API_KEY not set. "
                "Get a free key at https://openrouter.ai/settings/keys"
            )

    def complete(self, system: str, user: str, max_tokens: int = 1024) -> str:
        """Run a completion and return the assistant message text."""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "max_tokens": max_tokens,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        }
        r = httpx.post(self.BASE_URL, json=payload, headers=headers, timeout=60)
        r.raise_for_status()
        data = r.json()
        return data["choices"][0]["message"]["content"]
