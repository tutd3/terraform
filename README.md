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
│   └── dev/
│       ├── vpc/             # Stack terpisah, state sendiri (envs/dev/vpc/terraform.tfstate)
│       ├── s3/              # KATEGORI - tiap subfolder = 1 bucket S3
│       │   ├── app/         #   bucket pertama
│       │   └── test1-cempaka/
│       ├── ec2/             # KATEGORI - tiap subfolder = 1 instance EC2
│       │   └── example/     #   instance pertama (template untuk tambah instance baru)
│       └── eks/             # Stack terpisah, baca output vpc lewat terraform_remote_state
└── .github/workflows/
    ├── terraform-plan.yml   # Jalan otomatis tiap ada Pull Request ke main (plan tiap stack)
    └── terraform-apply.yml  # Jalan setelah merge ke main (atau manual trigger), nunggu
                              # 1x approval, lalu apply berurutan: vpc -> s3/* -> ec2/* -> eks
```

Tiap stack di `envs/dev/` itu **state Terraform-nya terpisah** (S3 key beda-beda).
Artinya kamu bisa `plan`/`apply` salah satu stack saja tanpa menyentuh yang lain
— misalnya ubah EC2 tidak akan pernah memicu perubahan di EKS atau S3.
Karena EC2 dan EKS butuh VPC, mereka baca output-nya lewat data source
`terraform_remote_state`, bukan lewat module Terraform biasa.

**Urutan wajib untuk bring-up pertama kali:** `vpc` harus di-apply duluan,
baru `ec2/*`/`eks` bisa jalan (karena mereka butuh state vpc sudah ada).
`s3/*` independen (tidak butuh vpc), bebas kapan saja. Workflow
`terraform-apply.yml` sudah menangani urutan ini otomatis.

### Punya banyak instance EC2 / bucket S3 untuk tujuan berbeda-beda

`envs/dev/s3/` dan `envs/dev/ec2/` adalah **kategori**, bukan satu stack
tunggal. Tiap subfolder di dalamnya adalah instance independen (state
sendiri), nama foldernya bebas sesuai tujuan - misalnya:

```
envs/dev/s3/
├── app/             # sudah ada
├── test1-cempaka/   # sudah ada
├── loki-logs/       # contoh: bucket untuk Loki
└── psql-logs/       # contoh: bucket untuk backup PostgreSQL

envs/dev/ec2/
├── example/   # sudah ada
├── psql/      # contoh: server PostgreSQL
└── posthog/   # contoh: self-hosted PostHog
```

Untuk tambah instance baru: copy salah satu folder yang sudah ada (mis.
`s3/app/` atau `ec2/example/`) jadi `<kategori>/<nama-baru>/`, ganti `key` di
`backend.tf` (jadi `envs/dev/<kategori>/<nama-baru>/terraform.tfstate`),
sesuaikan `main.tf`/`variables.tf` sesuai kebutuhan. Tidak perlu ubah workflow
sama sekali - CI otomatis men-discover semua subfolder di `s3/` dan `ec2/`.

Tiap instance EC2 bisa diatur:
- `public` (bool) - `true` = subnet publik (dapat IP publik), `false` = subnet
  privat (cuma bisa diakses dari dalam VPC, tetap bisa akses internet keluar
  lewat NAT gateway).
- `availability_zone` (string, mis. `"ap-southeast-3b"`) - kosongkan untuk
  otomatis pakai AZ pertama yang tersedia.

## Alur kerja (workflow sehari-hari)

1. Buat branch baru, ubah file di `envs/dev` atau `modules/`.
2. Buka Pull Request ke `main`.
3. GitHub Actions otomatis jalankan `terraform plan` dan komentar hasilnya di PR.
4. Review hasil plan, minta review orang lain kalau perlu, lalu merge PR.
5. Setelah merge, workflow apply akan **berhenti dan menunggu approval** kamu
   di tab "Actions" (karena GitHub Environment `production`/`staging` di-protect
   dengan required reviewer - lihat bagian "Environment production/staging" di
   bawah). Klik "Review deployments" -> Approve untuk lanjut apply.

## Apply sebagian stack saja (hemat cost / testing)

Tidak harus selalu apply semua stack. Dua cara:

1. **Manual, self-service (direkomendasikan):** tab **Actions** -> workflow
   **"Terraform Apply"** -> **Run workflow** -> isi field `stacks`, misal:
   - `vpc` - cuma VPC
   - `vpc s3 eks` (atau pakai koma: `vpc,s3,eks`) - beberapa stack
   - `s3` - semua bucket S3, atau `s3/loki-logs` - cuma satu bucket tertentu
   - `ec2` - semua instance EC2, atau `ec2/psql` - cuma satu instance tertentu
   - `k8s` bisa dipakai sebagai alias `eks`
   - Kosongkan untuk apply semua (default)

   Urutan eksekusi selalu dijaga otomatis (`vpc -> s3/* -> ec2/* -> eks`) apa pun
   urutan yang kamu ketik. Ada juga pilihan `environment` (production/staging,
   default production) di form yang sama. Tetap ada approval gate seperti biasa.

2. **Repo variable `APPLY_STACKS`:** default untuk auto-apply saat merge PR ke
   `main` (push trigger), format sama seperti input di atas. Kosongkan/hapus
   variable ini untuk balik ke apply-semua-stack sebagai default.
   ```bash
   gh variable set APPLY_STACKS --repo tutd3/terraform --body "vpc s3"
   ```

## Environment `production` / `staging`

Kredensial AWS (OIDC role) dan approval gate diatur lewat **GitHub
Environments** (Settings > Environments di repo ini), bukan di-hardcode di
workflow:

- **`production`** - sudah aktif, diisi `AWS_ROLE_ARN`/`AWS_REGION` (akun AWS
  yang sekarang ada). Ini default kalau tidak pilih environment lain.
- **`staging`** - sudah dibuat tapi **sengaja dikosongkan** `AWS_ROLE_ARN`-nya,
  supaya tidak ada yang tidak sengaja apply ke akun/role yang salah sebelum
  benar-benar ada setup staging terpisah. Isi lewat:
  ```bash
  gh variable set AWS_ROLE_ARN --repo tutd3/terraform --env staging --body "arn:aws:iam::<account-id>:role/<role-name>"
  gh variable set AWS_REGION --repo tutd3/terraform --env staging --body "ap-southeast-3"
  ```

**Catatan penting:** ini baru mengatur *kredensial* per-environment. Kode
Terraform di `envs/dev/` masih satu-satunya stack yang benar-benar ada -
memilih `staging` di form `workflow_dispatch` cuma ganti role AWS yang dipakai,
belum ada `envs/staging/` yang terpisah dari `envs/dev/`. Kalau nanti memang
butuh environment staging yang benar-benar terpisah infrastrukturnya,
duplikasi `envs/dev/` jadi `envs/staging/` (lihat bagian "Menambah resource
baru" di bawah).

## Sekali di awal (wajib, sebelum CI/CD bisa jalan)

Lihat [`bootstrap/README.md`](bootstrap/README.md). Ini membuat:
- S3 bucket untuk Terraform state
- IAM OIDC provider + role `gh-actions-terraform` yang dipakai GitHub Actions

Ini satu-satunya bagian yang perlu AWS credentials asli, dan **harus dijalankan
manual oleh manusia**, bukan lewat CI, karena CI butuh role itu untuk bisa
jalan (chicken-and-egg problem).

## Menambah resource baru

- Kalau bentuknya baru (misal: RDS, ElastiCache): buat modul baru di `modules/<nama>/`
  mengikuti pola yang sama (main.tf, variables.tf, outputs.tf).
- Kalau mau environment baru yang infrastrukturnya benar-benar terpisah
  (bukan cuma beda kredensial, lihat bagian "Environment production/staging"
  di atas): duplikasi seluruh folder `envs/dev` (semua stack & kategori di
  dalamnya) jadi `envs/staging`, ganti `key` di tiap `backend.tf` (termasuk
  referensi `terraform_remote_state` di `ec2/*`/`eks`) dan value-value di
  `variables.tf`.

## Keamanan

- Tidak ada AWS access key yang disimpan di mana pun (GitHub Secrets, kode,
  dll). Semua otentikasi CI lewat OIDC + IAM role.
- Role `gh-actions-terraform` saat ini pakai `AdministratorAccess` untuk
  mempercepat tahap awal development. **Rencanakan untuk mempersempit** ke
  custom policy begitu semua modul sudah stabil.
- Semua bucket S3 di-block public access + encryption by default.
- EC2 root volume dienkripsi, IMDSv2 diwajibkan.
