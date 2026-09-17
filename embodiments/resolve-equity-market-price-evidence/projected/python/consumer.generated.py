# GENERATED CAPABILITY CONSUMER SEAM. Do not hand-edit.
# canonicalGraphDigest: sha256:e2d87ee252ea78574abc47e6d02691369f5ddb9bbebffe2a287e724d9e4f67af
# realizedGraphDigest: sha256:1067f69a46ac7b31235a5648f0a127bea0d89b8458d56a45523bd303cf134b18
import importlib.util
import pathlib
import sys

_EXECUTION_PATH = pathlib.Path(__file__).resolve().with_name("consumer-execution.generated.py")
_EXECUTION_SPEC = importlib.util.spec_from_file_location("consumer_execution_generated", _EXECUTION_PATH)
_EXECUTION_MODULE = importlib.util.module_from_spec(_EXECUTION_SPEC)
_EXECUTION_SPEC.loader.exec_module(_EXECUTION_MODULE)
raise SystemExit(_EXECUTION_MODULE.cli(sys.argv[1:]))
