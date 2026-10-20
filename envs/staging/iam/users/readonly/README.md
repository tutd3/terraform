# User readonly

Taruh **1 file kosong per user** di folder ini. Nama file = nama IAM user AWS
yang mau didaftarkan ke group readonly (policy `ReadOnlyAccess`, dan kalau
stack `eks` ada, otomatis dapat akses Kubernetes view-only juga lewat
`AmazonEKSViewPolicy` - tidak perlu setting tambahan). Isi file tidak dipakai,
boleh kosong.

**Tambah user baru** (mis. "budi"):

```
touch envs/staging/iam/users/readonly/budi
```

Lalu buka PR seperti biasa. Setelah merge & apply, Terraform akan membuat
user IAM baru "budi" dan memasukkannya ke group readonly. Kalau user "budi"
SUDAH ADA di AWS sebelumnya (dibuat manual lewat Console), beri tahu dulu
sebelum merge - perlu `terraform import` dulu supaya Terraform tidak mencoba
membuat user baru yang namanya bentrok.

**Pindah ke admin:** pindahkan file ini ke folder `../admin/`. Ini AMAN -
tidak menghapus/membuat ulang user atau access key/password console-nya,
cuma mengganti keanggotaan group (lihat komentar di `modules/iam/main.tf`
soal kenapa ini aman).

**Hapus akses total:** hapus file ini lalu buka PR. User IAM tersebut (beserta
access key, password console, dll yang dikelola Terraform) akan benar-benar
dihapus saat PR di-merge & apply - bukan cuma dikeluarkan dari group. Kalau
cuma mau keluarkan user dari pengelolaan Terraform TANPA menghapus user
aslinya, jangan hapus file di sini - perlu `terraform state rm` manual,
bukan sekadar hapus file.
