import sys
from vyper.cli.vyper_compile import compile_files

import warnings

# temporarily disable python warnings because of an unuseful warning in Vyper 0.3.9
warnings.filterwarnings("ignore")


def compile_bytecode(filename: str) -> str:
    return compile_files([filename], ["bytecode"])[filename]["bytecode"]


def cli():
    if len(sys.argv) != 2:
        print("Usage: python compile_bytecode.py <filename>")
        sys.exit(1)

    print(compile_bytecode(sys.argv[1]))
