# Bootstrap (jalankan sendiri, sekali saja)

Folder ini membuat prasyarat sebelum CI/CD bisa mulai jalan. Ini **satu-satunya
bagian** yang perlu kamu jalankan manual dari laptop sendiri, memakai AWS
credentials milikmu sendiri (jangan pernah dibagikan ke siapa pun/AI apa pun).

## Langkah

1. Install Terraform (>= 1.10) kalau belum ada:
   ```bash
   brew install terraform
   ```

2. Konfigurasi AWS credentials di laptop kamu (kalau belum):
   ```bash
   aws configure
   ```
   Ini akan minta Access Key ID & Secret Access Key dari user IAM milikmu
   sendiri (bukan dari role `gh-actions-terraform`). Kalau belum ada, buat
   dulu satu IAM user untuk dirimu sendiri di AWS Console dengan akses admin.

3. Jalankan:
   ```bash
   cd bootstrap
   terraform init
   terraform plan
   terraform apply
   ```

4. Setelah selesai, cek output-nya:
   ```bash
   terraform output
   ```
   Pastikan `github_actions_role_arn` hasilnya persis:
   ```
   arn:aws:iam::094983223261:role/gh-actions-terraform
   ```

5. File `terraform.tfstate` di folder ini adalah satu-satunya "sumber
   kebenaran" untuk resource-resource di atas. Simpan baik-baik (jangan
   dihapus, jangan di-commit ke git — sudah masuk `.gitignore`).

Setelah langkah ini selesai, GitHub Actions di repo ini sudah bisa
`assume role` ke AWS tanpa perlu access key sama sekali.
