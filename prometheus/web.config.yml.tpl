basic_auth_users:
  {{ getSecret "admin_username" }}: {{ getSecret "admin_password_bcrypt" }}
