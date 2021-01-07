# :warning: :warning: WARNING :warning: :warning: 

**As of October 2020, this workaround is now deprecated and obsolete.
Cloud Run has an official feature (VPC egress) that allows you to configure
a static IP through Cloud NAT. Follow the
[step-by-step guide](https://cloud.google.com/run/docs/configuring/static-outbound-ip)
I developed to use this feature.**

# :warning: :warning: WARNING :warning: :warning: 

--------

# Static Outbound IP example for Cloud Run applications

This repository contains an example of a [Google Cloud Run][cr] application that
runs an SSH tunnel through a GCE instance within the container to route outbound
requests of the Cloud Run application through the static IP of the GCE instance.

**Read the accompanying blog post as well:** https://ahmet.im/blog/cloud-run-static-ip/

## Before you begin

1. Launch Google Cloud Shell (recommended, as it has al the tools required
   pre-installed).

1. Clone this repository and `cd` into it.

## Create a tunnel instance on GCE

1. Create a set of ssh key pairs so that your container can SSH into the VM.

    ```sh
    ssh-keygen -q -f ssh_key
    ```

   > Note that the private SSH key, which is a secret, will be bundled into the
   > container image, which can be compromised if anyone gets access to your
   > source code/build system. You can also use other means of delivering this
   > key to the container in the runtime (e.g. by downloading from a GCS
   > bucket, or using a secrets manager).

2. Create a Google Compute Engine instance (`f1-micro` in `us-central1` with
   name "tunnel"):

    ```sh
    gcloud compute instances create "tunnel" \
        --zone=us-central1-b \
        --machine-type=f1-micro
    ```

3. (Optional) You can go to the Cloud Console and
   [promote](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address#promote_ephemeral_ip)
   this VM’s ephemeral IP address to be a "static IP address". But, long as you
   don't delete this VM, its IP address will not change.

4. Upload the SSH public key (not a secret) to the VM to authenticate as user
   "tunnel":

    ```sh
    gcloud compute instances add-metadata "tunnel" \
        --zone=us-central1-b
        --metadata-from-file ssh-keys=<(echo "tunnel:$(cat ssh_key.pub)")
    ```

## (Optional) Inspect the application source code

Take time to understand:

- `entrypoint.sh`: runs a SSH client (as SOCKS5 TCP proxy server via GCE VM) and
  the `flask` Python application server.

  This script sets `HTTPS_PROXY=socks5://localhost:5000` environment variable to
  the Python app to use the proxy. However, this `HTTPS_PROXY` environment
  variable works the same way on many other languages, including **Go** as well.

  By setting `HTTPS_PROXY` environment variable you don't need to update your
  code to use the SOCKS5 proxy.

- `__init__.py` waits for the SSH port-forwarding server configured via
  `HTTPS_PROXY` to be accessible.

- `app.py`: starts a flask app querying https://ifconfig.me/ip and sends its
  result back.

- `Dockerfile` invokes `entrypoint.sh` via `tini` init system.

## Deploy Cloud Run application

1. Set up $PROJECT variable in your shell to your current project.

   ```sh
   PROJECT="$(gcloud config get-value core/project -q)"
   ```

1. Build and push the container image to Google Conatiner Registry.

    ```sh
    gcloud builds submit --tag gcr.io/$PROJECT/sample-tunnel
    ```

1. Find the `EXTERNAL_IP` address of the Compute Engine VM named "tunnel" you
   created earlier:

    ```sh
    gcloud compute instances list --filter=name=tunnel
    ```

1. Deploy to Cloud Run, by setting GCE_IP environment variable to the IP of the
   VM:

    ```sh
    gcloud beta run deploy sample-tunnel \
        --set-env-vars="GCE_IP=x.y.z.t" \
        --platform=managed \
        --region us-central1 \
        --allow-unauthenticated \
        --image=gcr.io/$PROJECT/sample-tunnel
    ```

## Query the application

When you visit the application’s public URL, you will see that the IP address
that it used to query https://ifconfig.me/ip is the IP address of the GCE
instance.

You can visit the application’s `/exit` endpoint to crash the Cloud Run
container instance, which would normally have a new dynamic IP assigned to the
instance, but in this case it remains the same as Cloud Run holds onto the
request.

---

Don't forget to check out the accompanying blog post: https://ahmet.im/blog/cloud-run-static-ip/

[cr]: https://cloud.google.com/run
