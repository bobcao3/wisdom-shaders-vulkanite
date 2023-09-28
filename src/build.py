from pathlib import Path
import os
import subprocess

def compile_pipeline(compiler: Path, src_path: Path, out_path: Path, entry_point: str = "computeMain", stage: str = "compute"):
    return subprocess.run([
            compiler,
            str(src_path),
            "-o", str(out_path),
            "-g2",
            "-O3",
            "-entry", entry_point,
            "-stage", stage,
            "-target", "glsl",
            "-I", str(src_path.parent),
            "-matrix-layout-column-major"
        ], check=True)

def compile_raygen(compiler: Path, src_path: Path, out_path: Path):
    return compile_pipeline(compiler, src_path, out_path, "raygenMain", "raygeneration")

def compile_raymiss(compiler: Path, src_path: Path, out_path: Path):
    return compile_pipeline(compiler, src_path, out_path, "missMain", "miss")

def compile_ahit(compiler: Path, src_path: Path, out_path: Path):
    return compile_pipeline(compiler, src_path, out_path, "anyhitMain", "anyhit")

def compile_chit(compiler: Path, src_path: Path, out_path: Path):
    return compile_pipeline(compiler, src_path, out_path, "closesthitMain", "closesthit")

def main():
    SRC_PATH = Path(__file__).resolve().parent
    BIN_PATH = SRC_PATH.parent / "bin"
    SLANG_PATH = BIN_PATH / "slang"
    OUT_PATH = SRC_PATH.parent / "shaders"

    if os.name == "posix":
        SLANGC = "slangc"
    elif os.name == "nt":
        SLANGC = SLANG_PATH / "bin/windows-x64/release/slangc.exe"
    else:
        raise Exception("unsupported platform")

    if not SLANGC.exists():
        raise Exception("slangc not found")
    
    try:
        compile_raygen(SLANGC, SRC_PATH / "rtPipeline0.slang", OUT_PATH / "ray0.rgen")
        compile_raymiss(SLANGC, SRC_PATH / "traversal.slang", OUT_PATH / "ray0_0.rmiss")
        compile_ahit(SLANGC, SRC_PATH / "traversal.slang", OUT_PATH / "ray0_0.rahit")
        compile_chit(SLANGC, SRC_PATH / "traversal.slang", OUT_PATH / "ray0_0.rchit")
    except subprocess.CalledProcessError as e:
        print(e)
        exit(1)

if __name__ == '__main__':
    main()
