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
│   ├── eks/           # EKS cluster + node group + EBS CSI driver (untuk PVC)
│   └── iam/           # IAM group readonly/admin + user (lihat "IAM user & akses" di bawah)
├── envs/
│   ├── production/        # ENVIRONMENT - sudah live, dipakai GitHub Environment "production"
│   │   ├── vpc/            # Stack terpisah, state sendiri
│   │   ├── iam/             # Stack terpisah, group readonly/admin + user
│   │   │   └── users.auto.tfvars  # Daftar nama user per group, dibaca otomatis
│   │   ├── s3/              # KATEGORI - tiap subfolder = 1 bucket S3
│   │   │   ├── app/
│   │   │   └── test1-cempaka/
│   │   ├── ec2/              # KATEGORI - tiap subfolder = 1 instance EC2
│   │   │   └── wetech-devops-prod/  # wetech-<service>-<environment>
│   │   └── eks/              # Stack terpisah, baca output vpc lewat terraform_remote_state
│   └── staging/            # ENVIRONMENT - struktur sama persis, belum pernah di-apply
│       └── ...                (lihat "Environment production/staging" di bawah)
└── .github/workflows/
    ├── terraform-plan.yml   # Jalan otomatis tiap ada Pull Request ke main (plan semua environment)
    └── terraform-apply.yml  # Jalan setelah merge ke main (atau manual trigger), nunggu
                              # 1x approval, lalu apply berurutan: vpc -> iam -> s3/* -> ec2/* -> eks
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

### Tambah route custom di VPC (VPN, VPC peering, Transit Gateway)

Selain route default (public -> internet gateway, private -> NAT gateway),
bisa tambah route lain lewat `additional_public_routes`/
`additional_private_routes` di `envs/<environment>/vpc/variables.tf`:

```hcl
variable "additional_private_routes" {
  default = [
    {
      cidr_block           = "192.168.50.0/24"   # CIDR tujuan
      network_interface_id = "eni-xxxxxxxx"       # mis. ENI server VPN
    },
  ]
}
```

Tiap elemen wajib isi `cidr_block` + **tepat satu** dari: `gateway_id`
(Virtual Private Gateway), `nat_gateway_id`, `transit_gateway_id`,
`vpc_peering_connection_id`, atau `network_interface_id` (mis. ENI instance
EC2 yang jadi VPN server - lebih umum dipakai daripada `instance_id`, yang
sejak AWS provider v5 sudah tidak didukung lagi di route table). Field lain
dikosongkan - AWS menolak route dengan 0 atau lebih dari 1 target.

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
├── wetech-devops-prod/   # sudah ada
├── wetech-psql-prod/     # contoh: server PostgreSQL
└── wetech-posthog-prod/  # contoh: self-hosted PostHog
```

**Naming standar untuk nama folder + `name` instance EC2:** `wetech-<service>-<environment>`
(mis. `wetech-devops-prod`, `wetech-psql-staging`) - `<service>` bebas sesuai
tujuan instance-nya, `<environment>` singkat (`prod`/`staging`).

Untuk tambah instance baru: copy salah satu folder yang sudah ada (mis.
`s3/app/` atau `ec2/wetech-devops-prod/`) jadi `<kategori>/<nama-baru>/`, ganti
`key` di `backend.tf` (jadi `envs/<environment>/<kategori>/<nama-baru>/terraform.tfstate`),
sesuaikan `main.tf`/`variables.tf` sesuai kebutuhan (termasuk `service_name`
untuk ikuti naming standar di atas). Tidak perlu ubah workflow sama sekali -
CI otomatis men-discover semua subfolder di `s3/` dan `ec2/`, di semua
environment.

Tiap instance EC2 bisa diatur:
- `public` (bool) - `true` = subnet publik (dapat IP publik), `false` = subnet
  privat (cuma bisa diakses dari dalam VPC, tetap bisa akses internet keluar
  lewat NAT gateway).
- `availability_zone` (string, mis. `"ap-southeast-3b"`) - kosongkan untuk
  otomatis pakai AZ pertama yang tersedia.
- `ami_id` - bebas OS apa pun (Windows Server, distro Linux lain, AMI
  custom/marketplace), tidak terbatas Amazon Linux. Kosongkan untuk otomatis
  pakai Amazon Linux 2023 terbaru (non-minimal, sudah ada SSM Agent).
- `root_volume_type` (`gp3` default, atau `gp2`/`io1`/`io2`/`st1`/`sc1`),
  `root_volume_iops`, `root_volume_throughput` (MB/s, **cuma berlaku untuk
  gp3**) - kosongkan `root_volume_iops`/`root_volume_throughput` untuk pakai
  default AWS (gp3: 3000 IOPS / 125 MB/s). `io1`/`io2` **wajib** isi
  `root_volume_iops` (AWS tidak punya default untuk tipe itu).

**Akses ke instance (SSH vs SSM):** default-nya **AWS Systems Manager Session
Manager** (`enable_ssm = true` di `modules/ec2`) - tidak perlu SSH key atau
buka port 22 sama sekali. Modul otomatis bikin IAM role + instance profile
dengan policy `AmazonSSMManagedInstanceCore` untuk tiap instance. Untuk
connect: `aws ssm start-session --target <instance-id>` (atau lewat AWS
Console > EC2 > Connect > Session Manager).

Siapa yang **boleh** mulai sesi SSM diatur lewat group IAM (`ssm:StartSession`
ada di policy `AdministratorAccess`, TIDAK ada di `ReadOnlyAccess`) - jadi
saat ini cuma user di group **admin** yang bisa SSM ke instance manapun,
sesuai desain (`readonly` benar-benar read-only, tidak bisa masuk shell).

Kalau tetap butuh SSH (jarang, SSM lebih aman & tidak perlu buka port):
set `enable_ssm = false` di instance tersebut, buat EC2 Key Pair manual
dulu di AWS (`aws ec2 create-key-pair`), isi `ec2_key_name`, dan tambahkan
`ingress_rules` untuk port 22 (ganti `cidr_blocks` ke IP kamu saja, jangan
`0.0.0.0/0`).

### IAM user & akses (readonly / admin)

`envs/<environment>/iam/` menyediakan 2 IAM group siap pakai per environment:
- **`<name_prefix>-readonly`** - policy `ReadOnlyAccess` (cuma bisa lihat)
- **`<name_prefix>-admin`** - policy `AdministratorAccess` (akses penuh)

Kalau stack `eks` ada, user di group ini juga otomatis dapat akses Kubernetes
yang setara (`AmazonEKSViewPolicy` untuk readonly, `AmazonEKSClusterAdminPolicy`
untuk admin) - tidak perlu setting tambahan, lihat `envs/<environment>/eks/main.tf`.

Untuk nambah/pindah/hapus user, edit `envs/<environment>/iam/users.auto.tfvars`
(file ini dibaca OTOMATIS oleh Terraform, tidak perlu `-var-file`):

```hcl
# envs/production/iam/users.auto.tfvars
readonly_users = ["test1", "budi"]
admin_users    = ["test2"]
```

lalu buka PR seperti biasa - setelah merge & apply, Terraform yang membuat
user IAM baru itu (bukan kamu bikin manual di AWS Console dulu). Pindah tier =
pindahkan nama dari satu list ke list lain (AMAN, tidak menghapus/membuat
ulang user aslinya - lihat komentar di `modules/iam/main.tf`). Hapus nama dari
kedua list = user ikut dihapus total saat PR berikutnya di-apply.

Kalau user yang mau didaftarkan **sudah ada** di AWS (dibuat manual lewat
Console sebelum ini, atau oleh orang lain), jangan langsung tambah nama &
merge - perlu `terraform import` dulu supaya Terraform tidak mencoba membuat
user baru yang namanya bentrok (lihat riwayat `test1`/`test2`/`terrafrom` di
repo ini sebagai contoh, termasuk kasus `terrafrom` yang sengaja dikeluarkan
dari pengelolaan Terraform lewat `terraform state rm` karena itu akun AWS
CLI yang tidak boleh ikut ter-destroy).

**Soal password console login:** secara default user yang dibuat TIDAK dapat
password (programmatic access only / kamu atur lewat access key secara
terpisah). Kalau butuh password Console, isi `console_login_pgp_key` dengan
PGP public key kamu (base64) - password akan di-generate acak dan
**dienkripsi pakai PGP key itu** di output Terraform (`sensitive = true`,
tidak pernah muncul plaintext di plan/log/chat). Cuma pemilik private key
yang bisa dekripsi (`terraform output -raw admin_encrypted_passwords | base64 -d | gpg -d`).
Kalau tidak butuh Console login, biarkan `console_login_pgp_key` kosong (default).

### Akses API server EKS (publik vs privat-lewat-VPN)

`enable_public_access` di `envs/<environment>/eks/variables.tf` - **default
`false`** (lebih aman): API server Kubernetes cuma bisa diakses dari **dalam
VPC** (lewat VPN/bastion yang masuk ke VPC ini), endpoint publik dimatikan
total. CI/CD tetap jalan normal walau `false` - Terraform mengelola cluster
lewat AWS EKS control plane API (`eks:*`), bukan lewat API server Kubernetes
langsung.

Set `true` kalau mau akses `kubectl` dari internet langsung tanpa VPN (mis.
sebelum VPN selesai dibangun) - **tidak disarankan untuk production**, karena
endpoint-nya jadi terbuka ke `0.0.0.0/0` tanpa batasan IP sama sekali.

### EKS node group - ukuran EBS root volume

`node_disk_size_gb` di `envs/<environment>/eks/variables.tf` (default `100`)
- ukuran EBS root volume tiap worker node. Default AWS kalau tidak diset
sama sekali cuma 20GB, sering kurang begitu banyak image container ditarik.
Naikkan kalau butuh lebih besar lagi, tidak ada batas atas khusus dari modul
ini (ikuti batas EBS biasa). IOPS/throughput node pakai default AWS (gp3:
3000 IOPS/125 MB/s) - belum bisa diatur manual, butuh Launch Template
terpisah kalau suatu saat perlu (perubahan lebih besar, belum ada di modul
ini sekarang).

### EKS node group - AZ untuk worker node (hemat cost)

`node_availability_zones` di `envs/<environment>/eks/variables.tf` (default
`["ap-southeast-3a"]` - cuma 1 AZ, hemat biaya) - AZ tempat worker node
ditempatkan (subnet PRIVAT di AZ itu). **Cluster control plane TETAP
multi-AZ** apa pun isi ini (wajib dari AWS, tidak bisa 1 AZ) - yang dibatasi
cuma node-nya.

Isi 2+ AZ untuk HA lebih tinggi, mis. `["ap-southeast-3a", "ap-southeast-3b"]`.
**Mengubah isi variable ini di cluster yang SUDAH ADA akan mengganti total
node group** (subnet node group adalah ForceNew di AWS - tidak bisa pindah
AZ in-place) - node lama dihancurkan, node baru dibuat di AZ yang baru. Ada
downtime singkat untuk pod yang jalan di node lama (termasuk addon sistem
seperti coredns) selama transisi.

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
     - `vpc iam s3 eks` (atau pakai koma: `vpc,iam,s3,eks`) - beberapa stack
     - `iam` - group & user IAM
     - `s3` - semua bucket S3, atau `s3/loki-logs` - cuma satu bucket tertentu
     - `ec2` - semua instance EC2, atau `ec2/psql` - cuma satu instance tertentu
     - `k8s` bisa dipakai sebagai alias `eks`
     - Kosongkan untuk apply semua stack di environment itu (default)

   Urutan eksekusi selalu dijaga otomatis (`vpc -> iam -> s3/* -> ec2/* -> eks`)
   apa pun urutan yang kamu ketik. Tetap ada approval gate seperti biasa.

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
  (struktur identik dengan production, prefix nama `wetech-staging`,
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
  resource (`wetech-production` -> `wetech-<nama-baru>`) dan nama bucket S3
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
