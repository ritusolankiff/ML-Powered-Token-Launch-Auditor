import argparse
import json

from analyzer.classify import audit_token

def main() -> None:
    parser = argparse.ArgumentParser(
        description="ML-Powered Token Launch Auditor (heuristic version)"
    )
    parser.add_argument(
        "--file",
        required=True,
        help="Path to Solidity token contract (e.g. data/tokens/safe_token_1.sol)",
    )
    args = parser.parse_args()

    result = audit_token(args.file)
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
