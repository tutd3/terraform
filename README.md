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
│       ├── vpc/       # Stack terpisah, state sendiri (envs/dev/vpc/terraform.tfstate)
│       ├── s3/         # Stack terpisah, state sendiri, tidak bergantung stack lain
│       ├── ec2/        # Stack terpisah, baca output vpc lewat terraform_remote_state
│       └── eks/        # Stack terpisah, baca output vpc lewat terraform_remote_state
└── .github/workflows/
    ├── terraform-plan.yml   # Jalan otomatis tiap ada Pull Request ke main (plan tiap stack)
    └── terraform-apply.yml  # Jalan setelah merge ke main, nunggu 1x approval manual,
                              # lalu apply berurutan: vpc -> s3 -> ec2 -> eks
```

Tiap stack di `envs/dev/` itu **state Terraform-nya terpisah** (S3 key beda-beda).
Artinya kamu bisa `plan`/`apply` salah satu stack saja tanpa menyentuh yang lain
— misalnya ubah EC2 tidak akan pernah memicu perubahan di EKS atau S3.
Karena EC2 dan EKS butuh VPC, mereka baca output-nya lewat data source
`terraform_remote_state`, bukan lewat module Terraform biasa.

**Urutan wajib untuk bring-up pertama kali:** `vpc` harus di-apply duluan,
baru `ec2`/`eks` bisa jalan (karena mereka butuh state vpc sudah ada).
`s3` independen, bebas kapan saja. Workflow `terraform-apply.yml` sudah
menangani urutan ini otomatis.

## Alur kerja (workflow sehari-hari)

1. Buat branch baru, ubah file di `envs/dev` atau `modules/`.
2. Buka Pull Request ke `main`.
3. GitHub Actions otomatis jalankan `terraform plan` dan komentar hasilnya di PR.
4. Review hasil plan, minta review orang lain kalau perlu, lalu merge PR.
5. Setelah merge, workflow apply akan **berhenti dan menunggu approval** kamu
   di tab "Actions" (karena environment `dev-apply` di-protect dengan required
   reviewer). Klik "Review deployments" -> Approve untuk lanjut apply.

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
