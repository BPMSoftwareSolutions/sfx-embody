# GENERATED CAPABILITY CONSUMER SEAM. Do not hand-edit.
# canonicalGraphDigest: sha256:6d8e145c32ebc8629dab66e0be7fe88e135968b4bdcd888ee3e266d712b41dbf
# realizedGraphDigest: sha256:c118fa66c8ef25d59a7d24c565d3d97614236ec481e9d99fe5b237603c3a5959
import importlib.util
import pathlib
import sys

_EXECUTION_PATH = pathlib.Path(__file__).resolve().with_name("consumer-execution.generated.py")
_EXECUTION_SPEC = importlib.util.spec_from_file_location("consumer_execution_generated", _EXECUTION_PATH)
_EXECUTION_MODULE = importlib.util.module_from_spec(_EXECUTION_SPEC)
_EXECUTION_SPEC.loader.exec_module(_EXECUTION_MODULE)
raise SystemExit(_EXECUTION_MODULE.cli(sys.argv[1:]))
