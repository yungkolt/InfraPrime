#!/bin/bash
# Generate self-signed SSL certificates for local development

# Create SSL directory if it doesn't exist
mkdir -p ssl

# Generate private key
openssl genrsa -out ssl/nginx.key 2048

# Generate certificate signing request
openssl req -new -key ssl/nginx.key -out ssl/nginx.csr -subj "/C=US/ST=Development/L=Local/O=InfraPrime/OU=DevTeam/CN=localhost"

# Generate self-signed certificate (valid for 365 days)
openssl x509 -req -days 365 -in ssl/nginx.csr -signkey ssl/nginx.key -out ssl/nginx.crt

# Set appropriate permissions
chmod 600 ssl/nginx.key
chmod 644 ssl/nginx.crt

# Clean up CSR file
rm ssl/nginx.csr

echo "SSL certificates generated successfully!"
echo "Certificate: ssl/nginx.crt"
echo "Private Key: ssl/nginx.key"
