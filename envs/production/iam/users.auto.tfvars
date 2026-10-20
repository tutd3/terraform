# Daftar user IAM untuk environment ini. File *.auto.tfvars dibaca otomatis
# oleh Terraform (tidak perlu -var-file). Lihat README.md bagian "IAM user &
# akses" untuk cara tambah/pindah tier/hapus user.
#
# Kosong sekarang (test1/test2 sudah di-destroy, terrafrom sengaja
# dikeluarkan dari pengelolaan Terraform - itu akun AWS CLI, lihat state rm
# di riwayat PR). Tambah nama di list di bawah untuk bikin user baru lewat
# Terraform (tidak perlu bikin manual di AWS Console lagi).

readonly_users = []

admin_users = []
