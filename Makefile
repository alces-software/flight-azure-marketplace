# Image config
IMAGE_TYPE=alces-flight-compute
IMAGE_VERSION=0.0.1-azure
IMAGE_NAME=$(IMAGE_TYPE)-$(IMAGE_VERSION)

# Libvirt/Oz config
KICKSTART=flight-compute-azure.ks.template
TDL=centos7.tdl
TDL_RENDERED=/tmp/$(IMAGE_NAME).tdl
OZ_CFG=oz.cfg
VM_DIR=/opt/vm
QEMU_IMG_BIN=$(VM_DIR)/qemu-img

# Azure config
STORAGE_ACCOUNT=alces
STORAGE_CONTAINER=images
RESOURCE_GROUP=alces

# Disk config
MB=$$((1024 * 1024))

all: setup build prepare convert

setup:
	@[ -d $(VM_DIR) ] || mkdir -p $(VM_DIR)/converted
	@cp $(TDL) $(TDL_RENDERED)
	@sed -i -e 's/c7/$(IMAGE_NAME)/g' $(TDL_RENDERED)

build:
	@echo "Building image $(IMAGE_NAME)"
	oz-install -d3 -u $(TDL_RENDERED) -x /tmp/$(IMAGE_NAME).xml \
					   -p -a $(KICKSTART) -c $(OZ_CFG) -t 1800

prepare:
	@echo "Preparing image"
	@virt-sysprep -a $(VM_DIR)/$(IMAGE_NAME).qcow2
	@echo "Sparsifying image"
	@virt-sparsify --compress --format qcow2 $(VM_DIR)/$(IMAGE_NAME).qcow2 \
							  $(VM_DIR)/converted/$(IMAGE_NAME).qcow2
	@echo "Created image $(VM_DIR)/converted/$(IMAGE_NAME).qcow2"

convert:
	@echo "Converting $(IMAGE_NAME) to RAW"
	@$(QEMU_IMG_BIN) convert -f qcow2 -O raw $(VM_DIR)/converted/$(IMAGE_NAME).qcow2 \
						       $(VM_DIR)/$(IMAGE_NAME).raw
	@$(eval DISK_SIZE=$(shell $(QEMU_IMG_BIN) info -f raw --output json $(VM_DIR)/$(IMAGE_NAME).raw | jq '."virtual-size"'))
	@$(eval DIVIDED_SIZE=$(shell echo $(DISK_SIZE)/$(MB) | bc))
	@$(eval ROUNDED_SIZE=$(shell echo $(DIVIDED_SIZE)*$(MB) | bc))
	@echo "Resizing RAW image to rounded size $(ROUNDED_SIZE)"
	@$(QEMU_IMG_BIN) resize -f raw $(VM_DIR)/$(IMAGE_NAME).raw $(ROUNDED_SIZE)
	@echo "Converting RAW image to VHD format"
	@$(QEMU_IMG_BIN) convert -f raw -O vpc -o subformat=fixed,force_size \
				 $(VM_DIR)/$(IMAGE_NAME).raw \
				 $(VM_DIR)/$(IMAGE_NAME).vhd
