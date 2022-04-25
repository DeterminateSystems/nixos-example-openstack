# NixOS example: building and deploying OpenStack images with Terraform

The goal of this repository is to demonstrate how to build NixOS images and upload them to your OpenStack provider.

### Assumptions

1. You have an existing OpenStack host which allows you to upload Images and SSH keys.
1. You have an existing SSH key.
1. You have Nix installed and available, and your Nix builds can use `/dev/kvm`. This may require bare metal hardware, or nested virtualization support from a virtualized server.

**Note:** Applying this Terraform module may cost money. It uploads the image and launches a server using that image.

## How to

### Build the image

In a terminal, build the image with:

```console
$ nix build .#images.zfs.x86_64-linux
```

Feel free to continue to Configuring Terraform while this builds.

This will produce a `./result` symlink containing the image and a JSON document describing the image.

### Configure Terraform

Under `./terraform` create a file called `variables.auto.tfvars` with:

```hcl
public_key = "your SSH public key"
```

and a file called `provider.tf` which configures your OpenStack provider. We used Vexxhost to test this, which used the following data:

```hcl
provider "openstack" {
  user_name = "..."
  tenant_id = "..."
  password  = "..."
  auth_url  = "https://auth.vexxhost.net/"
  region    = "ca-ymq-1"
}
```

Finally, initialize the Terraform configuration:

```
$ cd terraform
$ terraform init
```

### Upload the Image and Launch a Server

```
$ cd terraform
$ terraform apply
...
Apply complete! Resources: 2 added, 0 changed, 1 destroyed.

Outputs:

ipv4_addr = "199.19.213.115"
```

**Note:** The time it takse to upload the image depends on on your network speed and the performance of your OpenStack host. Testing this image took about 30 minutes.

### Connecting to the VM

You should now be able to SSH to the produced IPv4 address as the `root` user, using the private key corresponding to the provided public key:


```
$ ssh root@199.19.213.115
The authenticity of host '199.19.213.115 (199.19.213.115)' can't be established.
ED25519 key fingerprint is SHA256:xxx.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '199.19.213.115' (ED25519) to the list of known hosts.

[root@nixos-test:~]#
```
