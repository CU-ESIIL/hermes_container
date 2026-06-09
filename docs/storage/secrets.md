# Storage Secrets

Storage credentials are sensitive. They can grant access to unpublished data, private project outputs, cloud billing, or institutional systems.

Do not put real credentials in:

- `storage/storage.yml`
- Markdown files
- prompt logs
- screenshots
- Docker images
- GitHub issues or pull requests

Use environment variables such as:

```dotenv
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_ENDPOINT_URL=
WEBDAV_USER=
WEBDAV_PASSWORD=
IRODS_HOST=
IRODS_USER_NAME=
IRODS_PASSWORD=
```

If credentials are exposed, revoke or rotate them immediately, update `.env`, restart services, and inspect git history if they were committed.

