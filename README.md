# Fastly S3 Integration

Fastly integration with S3 to deliver and cache assets (text files, images and other binaries) stored in multiple S3 buckets through the Fastly CDN using the following setup:

* 1 Fastly service
* 1 or more user facing domains set up in Fastly
* 1 single origin host pointed to a <a href="https://docs.aws.amazon.com/general/latest/gr/s3.html" target="_blank">S3 regional endpoint</a>

The main goal of this tutorial is to describe how to set up a Fastly service to implement the following request forwarding schema:

    http[s]://<fastly_domain>/[<url_path_prefix>]/<bucket_name>/<s3_asset_path>
                                   |
                                   |
                                   |
                                   V
    http[s]://<bucket_name>.s3.<aws_region>.amazonaws.com/<s3_asset_path>

Which is based on S3 <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/VirtualHosting.html#virtual-hosted-style-access" target="_blank">virtual hosted-style URLs</a>virtual hosted-style URLs, instead of using the <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/VirtualHosting.html#path-style-access" target="_blank">path-style URLs</a>, which will be soon deprecated by AWS.

## Setup

Perform the following steps in Fastly:

1. <a href="https://docs.fastly.com/en/guides/working-with-services#creating-a-new-service" target="_blank">Create a new service</a>.

2. <a href="https://docs.fastly.com/en/guides/working-with-domains#creating-a-domain" target="_blank">Create a domain</a> (or several) for the service. A <a href="https://docs.fastly.com/en/guides/setting-up-free-tls" target="_blank">free TLS</a> option provided by Fastly can be used entering `<name>.global.ssl.fastly.net` as domain name.

3. <a href="https://docs.fastly.com/en/guides/working-with-services#creating-a-new-host" target="_blank">Create an origin host</a> for the desired S3 regional endpoint (`s3.<aws_region>.amazonaws.com`).

4. <a href="https://docs.fastly.com/en/guides/using-regular-vcl-snippets#creating-a-regular-vcl-snippet" target="_blank">Create the regular VCL snippets</a> described below:
    * Name => S3 Buckets Handling - RECV
    * Priority => 100
    * Type => <a href="https://developer.fastly.com/reference/vcl/subroutines/recv/" target="_blank">recv</a> (within subroutine -> `recv (vcl_recv)`)
    * VCL:

    ```
    if (req.url ~ "/([^/]+)/(.*)$") {
      set req.http.X-Bucket = re.group.1;
      set req.url = "/" re.group.2;
    }
    ```

    * Name => S3 Buckets Handling - MISS
    * Priority => 200
    * Type => <a href="https://developer.fastly.com/reference/vcl/subroutines/miss/" target="_blank">miss</a> (within subroutine -> `miss (vcl_miss)`)
    * VCL:

    ```
    if (req.http.X-Bucket) {
      set bereq.http.host = req.http.X-Bucket ".s3.eu-central-1.amazonaws.com";
    }
    ```

## Example VCL File

An [example VCL file](fastly-s3-integration.vcl) is included in this project so that it can be used as reference or even uploaded to an existing service (<a href="https://docs.fastly.com/en/guides/uploading-custom-vcl" target="_blank">Uploading custom VCL</a>).
