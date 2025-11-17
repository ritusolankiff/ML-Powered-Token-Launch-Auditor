from typing import Dict, Tuple

def score_token(features: Dict[str, float]) -> Tuple[int, str, str]:
    """Heuristic risk scoring model.

    Returns:
        score (0-100),
        risk_level ('Low' | 'Medium' | 'High'),
        label ('safe' | 'suspicious' | 'rugpull_candidate')
    """
    score = 0

    # High impact behaviors
    if features.get("has_owner_mint", 0) >= 1:
        score += 40
    elif features.get("has_mint", 0) >= 1:
        score += 20

    if features.get("has_set_fee", 0) >= 1:
        score += 25

    if features.get("has_blacklist", 0) >= 1:
        score += 20

    if features.get("has_trading_lock", 0) >= 1:
        score += 25

    if features.get("has_max_tx", 0) >= 1:
        score += 15

    # Structural complexity
    n_lines = features.get("n_lines", 0)
    if n_lines > 800:
        score += 15
    elif n_lines > 300:
        score += 8

    # Clamp score to [0, 100]
    score = max(0, min(100, score))

    if score <= 20:
        level = "Low"
        label = "safe"
    elif score <= 60:
        level = "Medium"
        label = "suspicious"
    else:
        level = "High"
        label = "rugpull_candidate"

    return int(score), level, label
