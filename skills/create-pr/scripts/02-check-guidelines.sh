#!/bin/bash
# 02-check-guidelines.sh - Check repository contribution guidelines and requirements
# Usage: ./02-check-guidelines.sh [repo_path]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
check() { echo -e "${BLUE}[CHECK]${NC} $*"; }

REPO_PATH="${1:-.}"
cd "$REPO_PATH"

info "Checking contribution guidelines for repository: $(basename "$PWD")"
echo ""

# Check for CONTRIBUTING.md
check "Looking for CONTRIBUTING.md..."
if [ -f "CONTRIBUTING.md" ]; then
    info "✅ Found CONTRIBUTING.md"
    echo ""
    echo "===== Contribution Guidelines (first 30 lines) ====="
    head -30 CONTRIBUTING.md
    echo "===== (see CONTRIBUTING.md for full details) ====="
    echo ""
else
    warn "No CONTRIBUTING.md found"
fi

# Check for CODE_OF_CONDUCT.md
check "Looking for CODE_OF_CONDUCT.md..."
if [ -f "CODE_OF_CONDUCT.md" ]; then
    info "✅ Found CODE_OF_CONDUCT.md - Please review community guidelines"
else
    warn "No CODE_OF_CONDUCT.md found"
fi

# Check for CLA
check "Looking for CLA requirements..."
CLA_FOUND=false
for file in CONTRIBUTING.md README.md .github/CONTRIBUTING.md docs/CONTRIBUTING.md; do
    if [ -f "$file" ] && grep -qi "CLA\|contributor license agreement" "$file"; then
        warn "⚠️  CLA (Contributor License Agreement) may be required"
        warn "    Check: $file"
        CLA_FOUND=true
        break
    fi
done
if [ "$CLA_FOUND" = false ]; then
    info "No CLA requirement detected"
fi

# Check for DCO (Developer Certificate of Origin)
check "Looking for DCO requirements..."
DCO_FOUND=false
for file in CONTRIBUTING.md README.md .github/CONTRIBUTING.md docs/CONTRIBUTING.md; do
    if [ -f "$file" ] && grep -qi "DCO\|sign-off\|signed-off-by" "$file"; then
        info "✅ DCO (Developer Certificate of Origin) required"
        info "    Use: git commit -s"
        DCO_FOUND=true
        break
    fi
done
if [ "$DCO_FOUND" = false ]; then
    warn "No explicit DCO requirement found, but it's a best practice to use -s flag"
fi

# Check for PR template
check "Looking for PR template..."
if [ -f ".github/PULL_REQUEST_TEMPLATE.md" ] || [ -f "PULL_REQUEST_TEMPLATE.md" ] || [ -f ".github/pull_request_template.md" ]; then
    info "✅ Found PR template - Your PR description should follow this format"
    if [ -f ".github/PULL_REQUEST_TEMPLATE.md" ]; then
        echo ""
        echo "===== PR Template ====="
        cat .github/PULL_REQUEST_TEMPLATE.md
        echo "===== (end of template) ====="
        echo ""
    fi
else
    warn "No PR template found"
fi

# Check for testing requirements
check "Looking for testing requirements..."
if [ -f "Makefile" ]; then
    info "✅ Found Makefile"
    if grep -q "^test:" Makefile; then
        info "    → Run tests with: make test"
    fi
    if grep -q "^lint:" Makefile; then
        info "    → Run linter with: make lint"
    fi
    if grep -q "^fmt:" Makefile; then
        info "    → Format code with: make fmt"
    fi
fi

# Check for CI configuration
check "Looking for CI/CD configuration..."
CI_FOUND=false
if [ -d ".github/workflows" ]; then
    info "✅ Found GitHub Actions workflows:"
    for workflow in .github/workflows/*.{yml,yaml}; do
        if [ -f "$workflow" ]; then
            info "    → $(basename "$workflow")"
            CI_FOUND=true
        fi
    done
fi
if [ -f ".travis.yml" ]; then
    info "✅ Found Travis CI configuration"
    CI_FOUND=true
fi
if [ -f ".circleci/config.yml" ]; then
    info "✅ Found CircleCI configuration"
    CI_FOUND=true
fi
if [ "$CI_FOUND" = false ]; then
    warn "No CI/CD configuration found"
fi

# Check commit message conventions
check "Looking for commit message conventions..."
for file in CONTRIBUTING.md README.md .github/CONTRIBUTING.md docs/CONTRIBUTING.md; do
    if [ -f "$file" ]; then
        if grep -qi "conventional commits\|commit message\|commit format" "$file"; then
            info "✅ Commit message conventions found - Please review: $file"
            break
        fi
    fi
done

# Summary
echo ""
info "========================================="
info "Summary"
info "========================================="
info "Before submitting your PR, ensure you:"
info "  1. ✓ Read CONTRIBUTING.md (if exists)"
info "  2. ✓ Sign commits with -s flag (DCO)"
info "  3. ✓ Run tests locally (make test)"
info "  4. ✓ Follow commit message conventions"
info "  5. ✓ Fill out PR template (if exists)"
info "========================================="
