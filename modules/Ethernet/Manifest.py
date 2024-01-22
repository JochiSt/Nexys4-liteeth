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

subprocess.run(["python pyVHDLinstTemplate.py"], shell=True, cwd=os.path.join( path, "../../utils/pyVHDLinstTemplate"))

print("#"*80, file=sys.stderr)
print("done", file=sys.stderr)
print("#"*80, file=sys.stderr)


files = [
    "build/gateware/liteeth_core.v",
    "build/gateware/liteeth_core.xdc",

    "readEthernetPacket.vhdl",
]