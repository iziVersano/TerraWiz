#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
  <title>TerraWiz — Issue #12</title>
  <style>
    body { font-family: monospace; padding: 2rem; background: #f0f4f8; }
    h1 { color: #2d6a4f; }
    .info { background: white; padding: 1rem; border-radius: 4px; margin-top: 1rem; }
  </style>
</head>
<body>
  <h1>Hello from TerraWiz!</h1>
  <div class="info">
    <p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>
    <p><strong>Availability Zone:</strong> ${AZ}</p>
  </div>
</body>
</html>
HTML
