# GENERATED CAPABILITY CONSUMER SEAM. Do not hand-edit.
# canonicalGraphDigest: sha256:97b39b5058357a925d7ea068f4dde79afdad74732cd0cc264a37b642d89e2357
# realizedGraphDigest: sha256:07e043eeda0b2f2a193d8a00a7ed3ea643d84e270c869bd483820b3085c3d3ad
import importlib.util
import pathlib
import sys

_EXECUTION_PATH = pathlib.Path(__file__).resolve().with_name("consumer-execution.generated.py")
_EXECUTION_SPEC = importlib.util.spec_from_file_location("consumer_execution_generated", _EXECUTION_PATH)
_EXECUTION_MODULE = importlib.util.module_from_spec(_EXECUTION_SPEC)
_EXECUTION_SPEC.loader.exec_module(_EXECUTION_MODULE)
raise SystemExit(_EXECUTION_MODULE.cli(sys.argv[1:]))
