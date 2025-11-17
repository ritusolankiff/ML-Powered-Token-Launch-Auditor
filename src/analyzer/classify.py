from pathlib import Path
from typing import Dict, Any

from .features import read_source, extract_token_features
from .model import score_token

def audit_token(path: str) -> Dict[str, Any]:
    """High-level API: audit a Solidity token file and return structured result."""
    p = Path(path)
    source = read_source(str(p))
    features = extract_token_features(source)
    score, level, label = score_token(features)

    return {
        "file": str(p),
        "features": features,
        "risk_score": score,
        "risk_level": level,
        "label": label,
    }
