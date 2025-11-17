# ML-Powered Token Launch Auditor  
### Static & ML-Inspired Risk Scoring for ERC-20 Token Smart Contracts

[![Security](https://img.shields.io/badge/security-audit-blue.svg)]()
[![Solidity](https://img.shields.io/badge/Solidity-0.8.x-black.svg)]()
[![Python](https://img.shields.io/badge/Python-3.10+-yellow.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()

---

## What Is This Project?

**ML-Powered Token Launch Auditor** is a security-focused toolkit that analyzes **ERC-20 style token smart contracts** and produces:

- A **numeric risk score (0–100)**
- A **risk level**: `Low`, `Medium`, or `High`
- A **semantic label**:
  - `safe`
  - `suspicious`
  - `rugpull_candidate`
- A feature breakdown explaining *why* the score was assigned

Under the hood, the project performs:

1. **Static feature extraction** from Solidity source code  
2. A **heuristic, ML-inspired scoring model** over those features  
3. A clean **JSON output** suitable for:
   - dashboards
   - further ML training
   - logs / SIEM
   - CI pipelines

Optionally, it also includes a **Solidity registry contract** that can store audit results on-chain.

This project is designed to be:

- **Educational**, easy to read and extend  
- **ML-ready**, feature-based, not just one-off rules  
- **Security-focused**, centered on real token scam patterns  
- **Practical**, CLI interface, sample tokens, ready to run

---

## Motivation

Token launches are one of the most common attack surfaces in Web3:

- Hidden owner mint functions → **infinite supply** → rugpulls  
- Blacklists & trading locks → **honeypot behavior** (you can buy but not sell)  
- Dynamic fee setters → **stealth tax updates**  
- MaxTx / MaxWallet → **anti-sell or anti-whale mechanics**  

Most retail users cannot read Solidity and are unable to evaluate:

> “Can the owner mint extra tokens?”  
> “Can they silently turn on a 99% tax?”  
> “Can they freeze trading whenever they want?”

This project provides a **first line of static defense**:

- It reads the Solidity source  
- Extracts security-relevant patterns  
- Computes a risk score  
- Explains the features used  

It is not a formal auditor, but it **captures many common scam patterns** and provides a strong foundation to build more advanced ML-based security tools.

---

## Project Structure

```text
ml-token-launch-auditor/
│
├── contracts/
│   └── TokenAuditRegistry.sol       # Optional: on-chain storage of audit results
│
├── src/
│   ├── analyzer/
│   │   ├── features.py              # Extracts token features from Solidity source
│   │   ├── model.py                 # Heuristic scoring model over features
│   │   └── classify.py              # High-level `audit_token()` function
│   └── cli.py                       # Command-line interface for auditing
│
├── data/
│   └── tokens/
│       ├── safe_token_1.sol         # Example of a safe token
│       ├── rugpull_token_1.sol      # Example of a rugpull-style token
│       └── suspicious_token_1.sol   # Example of a suspicious but not obvious token
│
├── requirements.txt                 # Placeholder for Python dependencies
└── README.md                        # This file
````

---

## Installation

### 1. Clone or unzip the project

```bash
cd /path/where/you/want
git clone https://github.com/AmirhosseinHonardoust/ml-token-launch-auditor.git
cd ml-token-launch-auditor
```

(or just copy the folder you already have into your repo)

---

### 2. (Recommended) Create a virtual environment

**Windows:**

```bash
python -m venv .venv
.\.venv\Scripts\activate
```

**Linux/macOS:**

```bash
python3 -m venv .venv
source .venv/bin/activate
```

If successful, you should see `(.venv)` at the start of your terminal prompt.

---

### 3. Install Python dependencies

For the current heuristic version, there are no heavy dependencies:

```bash
pip install -r requirements.txt
```

You can keep using only the Python standard library. If you later add ML models, you’ll add packages such as:

* `scikit-learn`
* `joblib`
* `pandas`
* `web3`

---

## How It Works, High-Level Flow

1. **User provides a Solidity file**
   Example: `data/tokens/rugpull_token_1.sol`

2. The tool:

   * Reads the source code as text
   * Applies regex-based pattern detection
   * Extracts a fixed set of features

3. The **scoring model** combines features into a numeric risk score using weightings inspired by real-world scam mechanics.

4. A final **label** and **risk level** are derived from the score.

5. A **JSON object** is printed to stdout for easy consumption or logging.

---

## Feature Engineering, What We Look For

All feature engineering is defined in `src/analyzer/features.py`.

### Structural Features

These basic metrics describe the “shape” of the contract:

* `n_lines`, total number of lines
* `n_public`, count of `public` occurrences
* `n_external`, count of `external` occurrences

They are used as rough proxies for:

* Contract complexity
* Exposure surface (public functions)

### Scam-Pattern Features

These are **binary features** (0 or 1) derived from regex patterns:

* `has_mint`

  * `mint(...)` exists somewhere in the contract
* `has_owner_mint`

  * `onlyOwner` and `function mint` appear together
  * Suggests the owner can mint new tokens unilaterally
* `has_set_fee`

  * functions like `setFee`, `setTax`, `setBuyFee`, `setSellFee`
  * Owner-controlled tax logic, can turn a token into a honeypot overnight
* `has_blacklist`

  * usage of `blacklist` or `isBlacklisted`
  * Owner can selectively prevent addresses from interacting
* `has_trading_lock`

  * `tradingOpen`, `enableTrading`, `disableTrading`, `lockTrading`
  * Owner can control if trading is open or closed
* `has_max_tx`

  * patterns like `maxTxAmount`, `maxTransactionAmount`, `maxTx`
  * Used to restrict transaction sizes (sometimes for anti-dump, sometimes for honeypots)

These features are all defined in this dictionary:

```python
DANGEROUS_PATTERNS: Dict[str, str] = {
    "has_mint": r"\bmint\s*\(",
    "has_owner_mint": r"onlyOwner[\s\S]*function\s+mint",
    "has_set_fee": r"setFee|setTax|setBuyFee|setSellFee",
    "has_blacklist": r"blacklist|isBlacklisted",
    "has_trading_lock": r"tradingOpen|enableTrading|disableTrading|lockTrading",
    "has_max_tx": r"maxTxAmount|maxTransactionAmount|maxTx",
}
```

---

## Risk Scoring, How the Model Works

All scoring logic lives in `src/analyzer/model.py`.

The goal is to:

* Keep it **interpretable**
* Use **weights** that reflect real risk impact
* Make it **easy to upgrade** to ML later

### 1. Start with score = 0

```python
score = 0
```

### 2. Apply weighted contributions

High-impact features:

```python
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
```

Structural complexity:

```python
n_lines = features.get("n_lines", 0)
if n_lines > 800:
    score += 15
elif n_lines > 300:
    score += 8
```

### 3. Clamp to [0, 100]

```python
score = max(0, min(100, score))
```

### 4. Map score → level & label

```python
if score <= 20:
    level = "Low"
    label = "safe"
elif score <= 60:
    level = "Medium"
    label = "suspicious"
else:
    level = "High"
    label = "rugpull_candidate"
```

---

## CLI Usage

The entry point is `src/cli.py`.

### Basic command

```bash
python src/cli.py --file data/tokens/safe_token_1.sol
```

* `--file` points to a Solidity `.sol` file
* You can give it **any** path: relative or absolute

Example with your own token:

```bash
python src/cli.py --file C:\Users\Amir\Desktop\MyToken.sol
```

---

## Understanding the Output

The CLI prints a JSON object like this:

```json
{
  "file": "data/tokens/rugpull_token_1.sol",
  "features": {
    "n_lines": 98.0,
    "n_public": 8.0,
    "n_external": 0.0,
    "has_mint": 1.0,
    "has_owner_mint": 1.0,
    "has_set_fee": 1.0,
    "has_blacklist": 1.0,
    "has_trading_lock": 1.0,
    "has_max_tx": 0.0
  },
  "risk_score": 100,
  "risk_level": "High",
  "label": "rugpull_candidate"
}
```

### Fields

* `file`

  * Path to the analyzed Solidity file

* `features`

  * The extracted feature set used to compute the score
  * You can log this for dataset creation, training ML models, etc.

* `risk_score`

  * Integer in `[0, 100]` representing the risk severity

* `risk_level`

  * `"Low"`, `"Medium"`, or `"High"`

* `label`

  * Simplified categorical label:

    * `"safe"`, no major red flags detected
    * `"suspicious"`, potentially risky mechanics (e.g. maxTx, trading locks)
    * `"rugpull_candidate"`, strong signals of owner power / abusive controls

---

## Example Tokens, Deep Dive

### 1. `safe_token_1.sol`

This contract:

* Has a fixed supply set in the constructor
* No mint function
* No blacklisting
* No trading lock mechanism
* No dynamic fee setters

Expected features (simplified):

```json
{
  "n_lines": ~40–60,
  "has_mint": 0,
  "has_owner_mint": 0,
  "has_set_fee": 0,
  "has_blacklist": 0,
  "has_trading_lock": 0,
  "has_max_tx": 0
}
```

Expected result:

* `risk_score`: 0–10
* `risk_level`: `Low`
* `label`: `safe`

---

### 2. `rugpull_token_1.sol`

This contract simulates **common scam patterns**:

* Owner-controlled `mint()`
* Owner-controlled `setFee()` → dynamic tax control
* Blacklist mapping → can block selling
* Trading gate (`tradingOpen`) → token can be deployed but trading closed
* Supply fully owned by deployer at start

Expected result:

* `has_owner_mint`: 1
* `has_set_fee`: 1
* `has_blacklist`: 1
* `has_trading_lock`: 1

Combined:

* Very high score (often 100)
* `risk_level`: `High`
* `label`: `rugpull_candidate`

This demonstrates how the feature set captures **owner power concentration**.

---

### 3. `suspicious_token_1.sol`

This contract:

* Has `maxTxAmount` → can restrict selling
* Has `tradingOpen` flag
* No blacklist or mint, but still can be used in tricky ways

Expected result:

* `has_max_tx`: 1
* `has_trading_lock`: 1
* No `mint` or `owner_mint`

This lands in:

* `risk_score`: mid-range
* `risk_level`: `Medium`
* `label`: `suspicious`

This simulates tokens where **mechanics can be abused**, but are not outright obvious rugpull patterns.

---

## Internals & Code Structure

### `src/analyzer/features.py`

Main responsibilities:

* Read Solidity file as text
* Count lines, `public`, `external`
* Run regex patterns to detect risky constructs
* Return a `Dict[str, float]` of features

You can add new patterns by:

1. Extending `DANGEROUS_PATTERNS`
2. Adjusting `model.py` to give them a weight

---

### `src/analyzer/model.py`

Implements the heuristic scoring model:

* Accepts features dict
* Adds risk contributions based on features
* Clamps score
* Maps score to level + label

To change behavior, you adjust:

* The weights assigned to each feature
* The thresholds for `Low` / `Medium` / `High`

---

### `src/analyzer/classify.py`

High-level API surface:

```python
def audit_token(path: str) -> Dict[str, Any]:
    ...
```

This is useful if you want to import the library in other Python code:

```python
from analyzer.classify import audit_token

result = audit_token("data/tokens/rugpull_token_1.sol")
print(result["risk_score"], result["risk_level"])
```

---

### `src/cli.py`

Console entry point for humans and scripts:

* Wraps `audit_token()`
* Parses `--file` argument
* Prints JSON to stdout

You can integrate it in CI like:

```bash
python src/cli.py --file contracts/YourToken.sol > audit_result.json
```

---

## Optional On-Chain Registry, `TokenAuditRegistry.sol`

The Solidity contract in `contracts/TokenAuditRegistry.sol` allows you to store audit results on-chain:

```solidity
function submitAudit(
    bytes32 tokenId,
    uint256 score,
    RiskLevel level,
    string calldata label,
    string calldata detailsJson
) external;
```

You could use:

* `tokenId = keccak256(abi.encodePacked(token_source_hash))`
* Or `tokenId = keccak256(abi.encodePacked(token_address))`

This enables:

* On-chain, verifiable audit records
* DApps querying `getAudit(tokenId)`
* Indexers (The Graph) to build dashboards

This is currently **optional** and not wired into the Python CLI, but it defines a clean interface for future integration.

---

## Extending With Real Machine Learning

Right now, the model is **heuristic but ML-inspired**. To make it truly ML-powered:

1. Generate a **dataset**:

   * Collect many token contracts (+ labels such as `scam`, `legit`, etc.)
   * Use `extract_token_features()` to create feature vectors
   * Store in CSV / parquet

2. Train a model (e.g. RandomForest):

```python
from sklearn.ensemble import RandomForestClassifier

# X: feature matrix, y: labels
clf = RandomForestClassifier(n_estimators=200, random_state=42)
clf.fit(X, y)
```

3. Save the model:

```python
import joblib
joblib.dump(clf, "artifacts/token_risk_model.joblib")
```

4. Modify `model.py` to:

* Load the trained model
* Use `features` as input to `clf.predict()` / `clf.predict_proba()`
* Derive `risk_score`, `risk_level`, `label` from probabilities

This transforms the current system into a **true ML-based auditor**.

---

## Limitations & Disclaimer

* This is **not** a formal security audit
* It does **not** guarantee that a token is safe or unsafe
* It only **flags patterns** commonly seen in rugpulls and scam tokens
* It does **not** simulate blockchain state or transactions
* It does **not** parse ASTs or bytecode (current version = regex/lexical)

Use this as:

* A **first-pass filter**
* A **research tool**
* A **component** in a larger analysis pipeline

Not as a sole decision-maker for high-value financial actions.

---

## Roadmap

* [ ] Add support for AST-based feature extraction
* [ ] Integrate real ML model (RandomForest / XGBoost)
* [ ] Build dataset loader for real-world token contracts
* [ ] Add explanations and SHAP-style feature importances
* [ ] Add web dashboard for visualizing audit results
* [ ] Add integration with `web3.py` to push results to `TokenAuditRegistry.sol`
* [ ] Add CI examples (GitHub Actions) to auto-audit tokens in PRs

---

## Contact / Contributions

Contributions are welcome:

* Add new features or risk patterns
* Improve the scoring weights
* Add real datasets for ML training
* Extend the Solidity registry
* Improve documentation

Feel free to open issues or pull requests if you experiment with new ideas.
