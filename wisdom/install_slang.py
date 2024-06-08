from pathlib import Path
import os
import subprocess
import platform
import wget
import shutil

VERSION = "v2024.1.17"

def os_arch(machine):
    machine2arch = {'AMD64': 'x64', 'x86_64': 'x64', 'i386': 'x86', 'x86': 'x86', 'arm64': 'arm64', 'aarch64': 'arm64'}
    return machine2arch.get(machine, None)

def os_is_arm(machine):
    return machine in ['arm64', 'aarch64']

def os_bits(machine):
    """Return bitness of operating system, or None if unknown."""
    machine2bits = {'AMD64': 64, 'x86_64': 64, 'i386': 32, 'x86': 32}
    return machine2bits.get(machine, None)

def main():
    machine = platform.machine()
    if os.name == "nt":
        if os_is_arm(machine):
            suffix = "win-arm64"
        else:
            suffix = "win" + str(os_bits(machine))
    elif os.name == "posix":
        if os_is_arm(machine):
            raise Exception("unsupported platform")
        else:
            if os_bits(machine) == 32:
                raise Exception("unsupported platform")
            suffix = "linux-x86_64"
    else:
        raise Exception("unsupported platform")

    slang_path = f"https://github.com/shader-slang/slang/releases/download/{VERSION}/slang-{VERSION[1:]}-{suffix}.zip"
    slang_install_path = Path.cwd() / "./bin/slang"
    slang_install_path.resolve()
    print("Installing slang to", slang_install_path)
    slang_install_path.mkdir(parents=True, exist_ok=True)
    fname = wget.download(slang_path)
    zip_path = Path.cwd() / fname
    shutil.unpack_archive(zip_path, slang_install_path)

if __name__ == '__main__':
    main()
