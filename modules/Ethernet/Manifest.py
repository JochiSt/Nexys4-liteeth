import subprocess
import sys

import os
path = os.path.dirname(os.path.abspath('__file__'))
print(path, file=sys.stderr)


print("", file=sys.stderr)
print("#"*80, file=sys.stderr)
print("\tgenerated the liteeth core", file=sys.stderr)
print("#"*80, file=sys.stderr)

subprocess.run(["./generate.sh"], shell=True, cwd=path)

print("#"*80, file=sys.stderr)
print("done", file=sys.stderr)
print("#"*80, file=sys.stderr)


files = [
    "build/gateware/liteeth_core.v",
    "build/gateware/liteeth_core.xdc",
]