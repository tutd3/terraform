# terraform

Infrastructure-as-code untuk AWS: VPC, EC2, S3, dan EKS (Kubernetes managed,
termasuk dukungan PVC lewat EBS CSI driver). Deploy otomatis lewat GitHub
Actions dengan OIDC (tanpa access key yang disimpan sebagai secret).

## Struktur folder

```
.
├── bootstrap/        # Dijalankan MANUAL sekali oleh manusia (lihat bootstrap/README.md)
│                      #   -> membuat S3 state bucket + IAM OIDC role untuk CI/CD
├── modules/
│   ├── vpc/           # VPC, subnet publik & privat, NAT gateway
│   ├── ec2/           # EC2 instance + security group
│   ├── s3/            # S3 bucket (versioning, encryption, block public access)
│   └── eks/           # EKS cluster + node group + EBS CSI driver (untuk PVC)
├── envs/
│   ├── production/        # ENVIRONMENT - sudah live, dipakai GitHub Environment "production"
│   │   ├── vpc/            # Stack terpisah, state sendiri
│   │   ├── s3/              # KATEGORI - tiap subfolder = 1 bucket S3
│   │   │   ├── app/
│   │   │   └── test1-cempaka/
│   │   ├── ec2/              # KATEGORI - tiap subfolder = 1 instance EC2
│   │   │   └── example/
│   │   └── eks/              # Stack terpisah, baca output vpc lewat terraform_remote_state
│   └── staging/            # ENVIRONMENT - struktur sama persis, belum pernah di-apply
│       └── ...                (lihat "Environment production/staging" di bawah)
└── .github/workflows/
    ├── terraform-plan.yml   # Jalan otomatis tiap ada Pull Request ke main (plan semua environment)
    └── terraform-apply.yml  # Jalan setelah merge ke main (atau manual trigger), nunggu
                              # 1x approval, lalu apply berurutan: vpc -> s3/* -> ec2/* -> eks
                              # untuk SATU environment yang dipilih (default production)
```

Tiap stack itu **state Terraform-nya terpisah** (S3 key beda-beda per
environment & per stack). Artinya kamu bisa `plan`/`apply` satu stack di satu
environment saja tanpa menyentuh yang lain — misalnya ubah EC2 di `production`
tidak akan pernah memicu perubahan di `staging`, atau di EKS/S3.

Karena EC2 dan EKS butuh VPC, mereka baca output-nya lewat data source
`terraform_remote_state` (bukan module Terraform biasa) - dari VPC di
environment yang SAMA (`envs/production/ec2/*` baca `envs/production/vpc`,
`envs/staging/ec2/*` baca `envs/staging/vpc`, tidak saling silang).

**Urutan wajib untuk bring-up pertama kali (per environment):** `vpc` harus
di-apply duluan, baru `ec2/*`/`eks` bisa jalan. `s3/*` independen (tidak butuh
vpc), bebas kapan saja. Workflow `terraform-apply.yml` sudah menangani urutan
ini otomatis.

### Punya banyak instance EC2 / bucket S3 untuk tujuan berbeda-beda

`s3/` dan `ec2/` di dalam tiap environment adalah **kategori**, bukan satu
stack tunggal. Tiap subfolder di dalamnya adalah instance independen (state
sendiri), nama foldernya bebas sesuai tujuan - misalnya:

```
envs/production/s3/
├── app/             # sudah ada
├── test1-cempaka/   # sudah ada
├── loki-logs/       # contoh: bucket untuk Loki
└── psql-logs/       # contoh: bucket untuk backup PostgreSQL

envs/production/ec2/
├── example/   # sudah ada
├── psql/      # contoh: server PostgreSQL
└── posthog/   # contoh: self-hosted PostHog
```

Untuk tambah instance baru: copy salah satu folder yang sudah ada (mis.
`s3/app/` atau `ec2/example/`) jadi `<kategori>/<nama-baru>/`, ganti `key` di
`backend.tf` (jadi `envs/<environment>/<kategori>/<nama-baru>/terraform.tfstate`),
sesuaikan `main.tf`/`variables.tf` sesuai kebutuhan. Tidak perlu ubah workflow
sama sekali - CI otomatis men-discover semua subfolder di `s3/` dan `ec2/`, di
semua environment.

Tiap instance EC2 bisa diatur:
- `public` (bool) - `true` = subnet publik (dapat IP publik), `false` = subnet
  privat (cuma bisa diakses dari dalam VPC, tetap bisa akses internet keluar
  lewat NAT gateway).
- `availability_zone` (string, mis. `"ap-southeast-3b"`) - kosongkan untuk
  otomatis pakai AZ pertama yang tersedia.

## Alur kerja (workflow sehari-hari)

1. Buat branch baru, ubah file di `envs/<environment>/...` atau `modules/`.
2. Buka Pull Request ke `main`.
3. GitHub Actions otomatis jalankan `terraform plan` untuk **semua environment**
   yang ada (`production`, `staging`) dan komentar hasilnya di PR.
4. Review hasil plan, minta review orang lain kalau perlu, lalu merge PR.
5. Setelah merge, workflow apply akan **berhenti dan menunggu approval** kamu
   di tab "Actions" (karena GitHub Environment `production`/`staging` di-protect
   dengan required reviewer - lihat bagian "Environment production/staging" di
   bawah). Klik "Review deployments" -> Approve untuk lanjut apply. Default-nya
   apply jalan untuk environment `production`.

## Apply sebagian stack saja (hemat cost / testing)

Tidak harus selalu apply semua stack. Dua cara:

1. **Manual, self-service (direkomendasikan):** tab **Actions** -> workflow
   **"Terraform Apply"** -> **Run workflow** -> isi:
   - `environment`: `production` atau `staging` (default `production`) -
     menentukan kredensial AWS **dan** direktori `envs/<environment>/` yang dipakai.
   - `stacks`, misal:
     - `vpc` - cuma VPC
     - `vpc s3 eks` (atau pakai koma: `vpc,s3,eks`) - beberapa stack
     - `s3` - semua bucket S3, atau `s3/loki-logs` - cuma satu bucket tertentu
     - `ec2` - semua instance EC2, atau `ec2/psql` - cuma satu instance tertentu
     - `k8s` bisa dipakai sebagai alias `eks`
     - Kosongkan untuk apply semua stack di environment itu (default)

   Urutan eksekusi selalu dijaga otomatis (`vpc -> s3/* -> ec2/* -> eks`) apa pun
   urutan yang kamu ketik. Tetap ada approval gate seperti biasa.

2. **Repo variable `APPLY_STACKS`:** default `stacks` untuk auto-apply saat
   merge PR ke `main` (push trigger, selalu pakai environment `production`),
   format sama seperti input di atas. Kosongkan/hapus variable ini untuk balik
   ke apply-semua-stack sebagai default.
   ```bash
   gh variable set APPLY_STACKS --repo tutd3/terraform --body "vpc s3"
   ```

## Environment `production` / `staging`

Ini **dua lapis yang saling berkaitan**:

1. **GitHub Environment** (Settings > Environments di repo ini) - nyimpan
   `AWS_ROLE_ARN`/`AWS_REGION` per-environment + approval gate (required
   reviewer). Dipilih lewat input `environment` saat `workflow_dispatch`,
   default `production` untuk push-trigger biasa.
2. **Direktori `envs/<environment>/`** - kode Terraform-nya sendiri. Nama
   environment yang dipilih di GitHub Environment **otomatis menentukan**
   direktori mana yang dipakai (`envs/production/` atau `envs/staging/`).

Status sekarang:
- **`production`** - sudah aktif, `AWS_ROLE_ARN`/`AWS_REGION` sudah diisi
  (akun AWS yang sekarang ada), dan `envs/production/` sudah berisi resource
  yang live (VPC, EC2 instance, dst).
- **`staging`** - environment & direktori `envs/staging/` sudah disiapkan
  (struktur identik dengan production, prefix nama `tutd3-staging`,
  nama bucket S3 sudah disesuaikan supaya tidak bentrok), tapi
  `AWS_ROLE_ARN`-nya **sengaja dikosongkan** - fail-safe supaya tidak ada yang
  tidak sengaja apply ke akun/role yang salah. Isi lewat:
  ```bash
  gh variable set AWS_ROLE_ARN --repo tutd3/terraform --env staging --body "arn:aws:iam::<account-id>:role/<role-name>"
  gh variable set AWS_REGION --repo tutd3/terraform --env staging --body "ap-southeast-3"
  ```
  Setelah itu, `staging` langsung bisa di-apply (pilih `environment: staging`
  saat `workflow_dispatch`) tanpa perlu ubah kode apa pun lagi.

**Catatan:** `terraform-plan.yml` (yang jalan di tiap PR) masih pakai SATU
kredensial AWS (repo-level variable) untuk nge-plan kedua environment,
karena saat ini keduanya di akun AWS yang sama. Kalau nanti `staging` pindah
ke akun AWS yang benar-benar terpisah, plan juga perlu disesuaikan supaya
pakai kredensial per-environment (bukan cuma apply).

## Sekali di awal (wajib, sebelum CI/CD bisa jalan)

Lihat [`bootstrap/README.md`](bootstrap/README.md). Ini membuat:
- S3 bucket untuk Terraform state
- IAM OIDC provider + role `gh-actions-terraform` yang dipakai GitHub Actions

Ini satu-satunya bagian yang perlu AWS credentials asli, dan **harus dijalankan
manual oleh manusia**, bukan lewat CI, karena CI butuh role itu untuk bisa
jalan (chicken-and-egg problem).

## Menambah resource baru

- Kalau bentuknya baru (misal: RDS, ElastiCache): buat modul baru di `modules/<nama>/`
  mengikuti pola yang sama (main.tf, variables.tf, outputs.tf), lalu pakai di
  environment mana pun yang butuh.
- Kalau mau environment baru lagi (selain production/staging): duplikasi
  seluruh folder `envs/production` (semua stack & kategori di dalamnya) jadi
  `envs/<nama-environment-baru>`, ganti `key` di tiap `backend.tf` (termasuk
  referensi `terraform_remote_state` di `ec2/*`/`eks`), ganti prefix nama
  resource (`tutd3-production` -> `tutd3-<nama-baru>`) dan nama bucket S3
  (harus unik global) di `variables.tf`. Lalu buat GitHub Environment baru
  dengan nama yang sama dan isi `AWS_ROLE_ARN`/`AWS_REGION`-nya, dan tambahkan
  namanya ke pilihan `environment` di `terraform-apply.yml`.

## Keamanan

- Tidak ada AWS access key yang disimpan di mana pun (GitHub Secrets, kode,
  dll). Semua otentikasi CI lewat OIDC + IAM role.
- Role `gh-actions-terraform` saat ini pakai `AdministratorAccess` untuk
  mempercepat tahap awal development. **Rencanakan untuk mempersempit** ke
  custom policy begitu semua modul sudah stabil.
- Semua bucket S3 di-block public access + encryption by default.
- EC2 root volume dienkripsi, IMDSv2 diwajibkan.
