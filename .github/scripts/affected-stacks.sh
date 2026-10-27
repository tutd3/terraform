#!/usr/bin/env bash
# Cari stack mana saja di SATU environment yang kena dampak dari daftar file
# yang berubah (hasil "git diff --name-only"), supaya plan/apply tidak perlu
# proses SEMUA stack kalau yang berubah cuma 1-2 saja.
#
# Aturan:
#   1. File berubah di dalam envs/<env>/<stack>/...  -> stack itu sendiri kena.
#   2. File berubah di modules/<nama>/...             -> stack di environment
#      ini yang main.tf-nya langsung "source" dari modules/<nama> ikut kena.
#      TIDAK dirambatkan ke stack lain (mis. eks/ec2 yang baca vpc lewat
#      terraform_remote_state) karena remote_state baca STATE yang sudah
#      ter-apply, bukan source module langsung - aman untuk tidak ikut
#      re-apply.
#
# Usage  : affected-stacks.sh <env> <file-berisi-daftar-path-yang-berubah>
# Output : 1 baris per stack yang kena dampak (mis. "vpc", "s3/app"), urutan
#          TETAP vpc -> iam -> s3/* -> ecr/* -> ec2/* -> eks, tanpa duplikat.
#          Kosong (tanpa output) kalau tidak ada stack yang kena di
#          environment ini.

set -euo pipefail

env="$1"
changed_file="$2"
base="envs/$env"

[ -d "$base" ] || exit 0

all_stacks=()
[ -d "$base/vpc" ] && all_stacks+=("vpc")
[ -d "$base/iam" ] && all_stacks+=("iam")
for d in "$base"/s3/*/; do
  [ -d "$d" ] || continue
  all_stacks+=("s3/$(basename "$d")")
done
for d in "$base"/ecr/*/; do
  [ -d "$d" ] || continue
  all_stacks+=("ecr/$(basename "$d")")
done
for d in "$base"/ec2/*/; do
  [ -d "$d" ] || continue
  all_stacks+=("ec2/$(basename "$d")")
done
[ -d "$base/eks" ] && all_stacks+=("eks")

changed_modules="$(grep -o '^modules/[^/]*' "$changed_file" 2>/dev/null | cut -d/ -f2 | sort -u || true)"

for stack in "${all_stacks[@]}"; do
  dir="$base/$stack"

  # Kasus 1: ada file yang berubah langsung di dalam stack ini.
  if grep -q "^${dir}/" "$changed_file"; then
    echo "$stack"
    continue
  fi

  # Kasus 2: stack ini konsumer LANGSUNG dari salah satu module yang berubah.
  if [ -n "$changed_modules" ] && [ -f "$dir/main.tf" ]; then
    while IFS= read -r module_name; do
      [ -z "$module_name" ] && continue
      if grep -q "modules/${module_name}\"" "$dir/main.tf"; then
        echo "$stack"
        break
      fi
    done <<<"$changed_modules"
  fi
done
