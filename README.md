# Fastly S3 Integration

Fastly integration with S3 to deliver and cache assets (text files, images and other binaries) stored in multiple S3 buckets through the Fastly CDN using the following setup:

* 1 Fastly service
* 1 or more user facing domains setup in Fastly
* 1 single origin host pointed to a [S3 regional endpoint](https://docs.aws.amazon.com/general/latest/gr/s3.html)
