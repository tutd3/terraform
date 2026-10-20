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
│       ├── vpc/           # Stack terpisah, state sendiri (envs/dev/vpc/terraform.tfstate)
│       ├── s3/             # Stack terpisah, state sendiri, tidak bergantung stack lain
│       ├── ec2/            # KATEGORI, bukan satu stack - tiap subfolder = 1 instance EC2
│       │   └── example/    #   instance pertama (template untuk tambah instance baru)
│       └── eks/            # Stack terpisah, baca output vpc lewat terraform_remote_state
└── .github/workflows/
    ├── terraform-plan.yml   # Jalan otomatis tiap ada Pull Request ke main (plan tiap stack)
    └── terraform-apply.yml  # Jalan setelah merge ke main (atau manual trigger), nunggu
                              # 1x approval, lalu apply berurutan: vpc -> s3 -> ec2/* -> eks
```

Tiap stack di `envs/dev/` itu **state Terraform-nya terpisah** (S3 key beda-beda).
Artinya kamu bisa `plan`/`apply` salah satu stack saja tanpa menyentuh yang lain
— misalnya ubah EC2 tidak akan pernah memicu perubahan di EKS atau S3.
Karena EC2 dan EKS butuh VPC, mereka baca output-nya lewat data source
`terraform_remote_state`, bukan lewat module Terraform biasa.

**Urutan wajib untuk bring-up pertama kali:** `vpc` harus di-apply duluan,
baru `ec2/*`/`eks` bisa jalan (karena mereka butuh state vpc sudah ada).
`s3` independen, bebas kapan saja. Workflow `terraform-apply.yml` sudah
menangani urutan ini otomatis.

### Punya banyak instance EC2 untuk tujuan berbeda-beda

`envs/dev/ec2/` adalah kategori, bukan satu stack tunggal. Tiap subfolder di
dalamnya adalah instance EC2 independen (state sendiri), nama foldernya bebas
sesuai tujuan - misalnya:

```
envs/dev/ec2/
├── example/   # sudah ada
├── psql/      # contoh: server PostgreSQL
└── posthog/   # contoh: self-hosted PostHog
```

Untuk tambah instance baru: copy folder `ec2/example/` jadi `ec2/<nama-baru>/`,
ganti `key` di `backend.tf` (jadi `envs/dev/ec2/<nama-baru>/terraform.tfstate`),
sesuaikan `main.tf`/`variables.tf` sesuai kebutuhan (ukuran instance, AMI,
public/private, dll). Tidak perlu ubah workflow sama sekali - CI otomatis
men-discover semua subfolder di `ec2/`.

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
   di tab "Actions" (karena environment `dev-apply` di-protect dengan required
   reviewer). Klik "Review deployments" -> Approve untuk lanjut apply.

## Apply sebagian stack saja (hemat cost / testing)

Tidak harus selalu apply semua stack. Dua cara:

1. **Manual, self-service (direkomendasikan):** tab **Actions** -> workflow
   **"Terraform Apply"** -> **Run workflow** -> isi field `stacks`, misal:
   - `vpc` - cuma VPC
   - `vpc s3 eks` (atau pakai koma: `vpc,s3,eks`) - beberapa stack
   - `ec2` - semua instance EC2
   - `ec2/psql` - cuma instance EC2 tertentu
   - `k8s` bisa dipakai sebagai alias `eks`
   - Kosongkan untuk apply semua (default)

   Urutan eksekusi selalu dijaga otomatis (`vpc -> s3 -> ec2/* -> eks`) apa pun
   urutan yang kamu ketik. Tetap ada approval gate seperti biasa.

2. **Repo variable `APPLY_STACKS`:** default untuk auto-apply saat merge PR ke
   `main` (push trigger), format sama seperti input di atas. Kosongkan/hapus
   variable ini untuk balik ke apply-semua-stack sebagai default.
   ```bash
   gh variable set APPLY_STACKS --repo tutd3/terraform --body "vpc s3"
   ```

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
- Kalau cuma nambah environment baru (misal staging/prod): duplikasi seluruh
  folder `envs/dev` (semua stack di dalamnya) jadi `envs/staging`, ganti `key`
  di tiap `backend.tf` (termasuk referensi `terraform_remote_state` di
  `ec2/eks`) dan value-value di `variables.tf`.

## Keamanan

- Tidak ada AWS access key yang disimpan di mana pun (GitHub Secrets, kode,
  dll). Semua otentikasi CI lewat OIDC + IAM role.
- Role `gh-actions-terraform` saat ini pakai `AdministratorAccess` untuk
  mempercepat tahap awal development. **Rencanakan untuk mempersempit** ke
  custom policy begitu semua modul sudah stabil.
- Semua bucket S3 di-block public access + encryption by default.
- EC2 root volume dienkripsi, IMDSv2 diwajibkan.
