# aws/s3-bucket

Private, KMS-encrypted, versioned S3 bucket.

## Security defaults

- **All four public access blocks on** — the bucket cannot be made public by a
  later ACL or policy change.
- **Bucket policy denies non-TLS requests** and any upload not encrypted with
  KMS.
- **`BucketOwnerEnforced`** ownership disables ACLs entirely.
- **Versioning on** with superseded versions expiring after 90 days, and
  incomplete multipart uploads aborted after 7.
- **Dedicated auto-rotating KMS key** with S3 Bucket Keys enabled.

## Static sites

`static_website = true` adds index/error document routing, but the bucket stays
private — front it with CloudFront using an Origin Access Control. Grant the
distribution `kms:Decrypt` on `kms_key_arn`, or objects will fail to serve.

## Usage

```hcl
module "assets" {
  source = "../../infrastructure-modules/aws/s3-bucket"

  name = "acme-platform-assets-prod"
  tags = { Environment = "prod" }
}
```
