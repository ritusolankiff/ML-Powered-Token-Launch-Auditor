import re
from pathlib import Path
from typing import Dict

# Patterns associated with common scammy / rugpull behavior in ERC-20-style tokens
DANGEROUS_PATTERNS: Dict[str, str] = {
    "has_mint": r"\bmint\s*\(",
    "has_owner_mint": r"onlyOwner[\s\S]*function\s+mint",
    "has_set_fee": r"setFee|setTax|setBuyFee|setSellFee",
    "has_blacklist": r"blacklist|isBlacklisted",
    "has_trading_lock": r"tradingOpen|enableTrading|disableTrading|lockTrading",
    "has_max_tx": r"maxTxAmount|maxTransactionAmount|maxTx",
}

def read_source(path: str) -> str:
    """Read Solidity source code from a file."""
    return Path(path).read_text(encoding="utf-8")

def extract_token_features(source: str) -> Dict[str, float]:
    """Extract simple lexical features from a token contract's Solidity source."""
    lines = source.splitlines()

    features: Dict[str, float] = {
        "n_lines": float(len(lines)),
        "n_public": float(len(re.findall(r"\bpublic\b", source))),
        "n_external": float(len(re.findall(r"\bexternal\b", source))),
    }

    # Pattern-based features
    for name, pattern in DANGEROUS_PATTERNS.items():
        features[name] = 1.0 if re.search(pattern, source, flags=re.IGNORECASE) else 0.0

    return features
