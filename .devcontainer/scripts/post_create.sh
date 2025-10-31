#!/usr/bin/env bash
set -euo pipefail

echo "[post_create] Starting development environment setup..."


# Ensure inside workspace root
cd /workspaces/pyproj

# Detect Python scripts bin path for PATH adjustments
PY_SCRIPTS_DIR=$(python -c 'import sys,os; print(os.path.dirname(sys.executable)+"/../python"+"/"+sys.version.split()[0]+"/bin")' 2>/dev/null || true)
ALT_PY_SCRIPTS_DIR=/usr/local/python/$(python -c 'import sys; print("%d.%d.%d"%sys.version_info[:3])')/bin
for candidate in "$PY_SCRIPTS_DIR" "$ALT_PY_SCRIPTS_DIR" /usr/local/python/3.13.7/bin; do
  if [ -d "$candidate" ]; then
    export PATH="$candidate:$PATH"
  fi
done

# Establish system PROJ installation variables
if command -v proj >/dev/null 2>&1; then
  # Common Debian/Ubuntu paths
  if [ -d /usr/share/proj ]; then
    export PROJ_DIR=/usr
    export PROJ_INCDIR=/usr/include
    # Choose lib dir
    if [ -d /usr/lib/x86_64-linux-gnu ]; then
      export PROJ_LIBDIR=/usr/lib/x86_64-linux-gnu
    else
      export PROJ_LIBDIR=/usr/lib
    fi
  elif [ -d /usr/local/share/proj ]; then
    export PROJ_DIR=/usr/local
    export PROJ_INCDIR=/usr/local/include
    export PROJ_LIBDIR=/usr/local/lib
  fi
fi

# Fallback guesses if still unset
export PROJ_DIR=${PROJ_DIR:-/usr}
export PROJ_INCDIR=${PROJ_INCDIR:-$PROJ_DIR/include}
if [ -z "${PROJ_LIBDIR:-}" ]; then
  for c in "$PROJ_DIR/lib" "$PROJ_DIR/lib64" /usr/lib/x86_64-linux-gnu; do
    [ -d "$c" ] && export PROJ_LIBDIR="$c" && break
  done
fi

echo "[post_create] PROJ_DIR=$PROJ_DIR"
echo "[post_create] PROJ_INCDIR=$PROJ_INCDIR"
echo "[post_create] PROJ_LIBDIR=$PROJ_LIBDIR"

# Remove empty internal proj_dir that triggers internal compilation path logic
if [ -d pyproj/proj_dir ] && [ -z "$(ls -A pyproj/proj_dir 2>/dev/null)" ]; then
  rmdir pyproj/proj_dir || true
  echo "[post_create] Removed empty pyproj/proj_dir to force system PROJ usage."
fi

# Initialize git LFS if available
if command -v git-lfs >/dev/null 2>&1; then
  git lfs install --skip-repo || true
  # Also attempt repo-specific install (non-fatal)
  git lfs install || true
  echo "[post_create] git-lfs initialized."
else
  echo "[post_create] git-lfs not found (unexpected)."
fi

python -m pip install --upgrade pip

# Install dev + test + docs deps
python -m pip install -r requirements-dev.txt
python -m pip install -r requirements-test.txt || true  # optional extras may fail on py>=3.12
python -m pip install -r requirements-docs.txt

# Editable install with coverage option
export PYPROJ_FULL_COVERAGE=YES
python -m pip install --no-build-isolation -e .

# Install pre-commit hooks if available
if command -v pre-commit >/dev/null 2>&1; then
  pre-commit install --install-hooks || true
fi

# Show versions
python -c "import pyproj, sys; print('pyproj', pyproj.__version__); print('Python', sys.version)"
proj 2>/dev/null | head -n1 || echo "proj binary not found"


echo "[post_create] Setup complete."
