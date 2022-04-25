terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.47.0"
    }
  }
}

locals {
  imagejson      = jsondecode(file("${path.module}/../result/nix-support/image-info.json"))
  label          = local.imagejson["label"]
  root_disk_file = local.imagejson["disks"]["root"]["file"]
}

resource "openstack_images_image_v2" "nixos_zfs" {
  name             = "NixOS-ZFS-${local.label}"
  local_file_path  = local.root_disk_file
  container_format = "bare"
  disk_format      = "qcow2"

  properties = {
    architecture     = "x86_64"
    hw_firmware_type = "uefi"
  }
}

resource "openstack_compute_keypair_v2" "mykeypair" {
  name       = "my-key-pair"
  public_key = var.public_key
}

# Create a web server
resource "openstack_compute_instance_v2" "test_server" {
  name      = "nixos-test"
  flavor_id = "2f8730dd-7688-4b72-a512-99fb9a482414"
  key_pair  = openstack_compute_keypair_v2.mykeypair.name

  block_device {
    delete_on_termination = true
    uuid                  = openstack_images_image_v2.nixos_zfs.id
    source_type           = "image"
    volume_size           = 50
    destination_type      = "volume"
    boot_index            = 0
  }

}
output "ipv4_addr" {
  value = openstack_compute_instance_v2.test_server.access_ip_v4
}