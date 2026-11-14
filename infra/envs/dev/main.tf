locals {
  name = "llm-tollgate"
}

module "network" {
  source = "../../modules/network"
  name   = local.name
}

module "compute" {
  source            = "../../modules/compute"
  name              = local.name
  subnet_id         = module.network.public_subnet_ids["ap-northeast-2a"]
  security_group_id = module.network.app_sg_id
}
