# Configure the OpenStack Provider
provider "openstack" {
  user_name = var.username
  tenant_id = var.project_id
  password  = var.password
  auth_url  = var.auth_url
  region    = var.cloud_region
  insecure  = true
}

resource "openstack_compute_keypair_v2" "basic_keypair" {
  name       = "${var.cluster_name}_keypair"
  public_key = file(var.ssh_pub_key)
}


data "template_file" "master_init" {
  template = file("${path.module}/scripts/master.cfg.tpl")

  vars = {
    bootstrap_token        = var.bootstrap_token != "" ? var.bootstrap_token : format("%s.%s", random_string.firstpart.result, random_string.secondpart.result)
    username               = var.username
    password               = var.password
    project_id             = var.project_id
    subnet_id              = openstack_networking_subnet_v2.cluster_subnet.id
    external_ip            = openstack_networking_floatingip_v2.public_ip.address
    internal_ip            = openstack_networking_port_v2.master.all_fixed_ips.0
    kubernetes_version     = var.kubernetes_version
    kubernetes_cni_version = var.kubernetes_cni_version
    pod_subnet             = var.pod_subnet
    public_network_id      = data.openstack_networking_network_v2.public.id
    auth_url               = var.auth_url
    domain_name            = var.domain_name
    containerd_version     = var.containerd_version
  }
}

# Render a multi-part cloudinit config making use of the part
# above, and other source files
data "template_cloudinit_config" "master_config" {
  gzip          = false
  base64_encode = false

  part {
    content = data.template_file.master_init.rendered
  }
}

resource "openstack_networking_port_v2" "master" {
  network_id         = openstack_networking_network_v2.private.id
  admin_state_up     = "true"
  security_group_ids = [openstack_networking_secgroup_v2.secgroup_master.id, openstack_networking_secgroup_v2.secgroup_node.id, openstack_networking_secgroup_v2.secgroup_master.id]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
  }
}

resource "openstack_compute_instance_v2" "master" {
  name        = "${var.cluster_name}-master"
  flavor_name = var.flavor
  key_pair    = openstack_compute_keypair_v2.basic_keypair.id
  user_data   = data.template_cloudinit_config.master_config.rendered

  metadata = {
    kubernetes = "master"
    cluster    = var.cluster_name
  }

  network {
    port = openstack_networking_port_v2.master.id
  }

  block_device {
    uuid                  = var.vms_image_id
    source_type           = "image"
    volume_size           = var.master_data_volume_size
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
  }
}


data "template_file" "node_init" {
  template = file("${path.module}/scripts/node.cfg.tpl")

  vars = {
    bootstrap_token        = var.bootstrap_token != "" ? var.bootstrap_token : format("%s.%s", random_string.firstpart.result, random_string.secondpart.result)
    username               = var.username
    password               = var.password
    project_id             = var.project_id
    subnet_id              = openstack_networking_subnet_v2.cluster_subnet.id
    api_server             = openstack_compute_instance_v2.master.access_ip_v4
    public_network_id      = data.openstack_networking_network_v2.public.id
    auth_url               = var.auth_url
    domain_name            = var.domain_name
    containerd_version     = var.containerd_version
    kubernetes_version     = var.kubernetes_version
    kubernetes_cni_version = var.kubernetes_cni_version
  }
}

# Render a multi-part cloudinit config making use of the part
# above, and other source files
data "template_cloudinit_config" "node_config" {
  gzip          = false
  base64_encode = false

  part {
    content = data.template_file.node_init.rendered
  }
}

resource "openstack_compute_instance_v2" "node" {
  count           = var.node_count
  name            = "${var.cluster_name}-node-${count.index}"
  flavor_name     = var.flavor
  key_pair        = openstack_compute_keypair_v2.basic_keypair.id
  security_groups = [openstack_networking_secgroup_v2.secgroup_node.name]
  user_data       = data.template_cloudinit_config.node_config.rendered

  metadata = {
    kubernetes = "node"
    cluster    = var.cluster_name
  }

  network {
    uuid = openstack_networking_network_v2.private.id
  }

  block_device {
    uuid                  = var.vms_image_id
    source_type           = "image"
    volume_size           = var.node_data_volume_size
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
  }
}
