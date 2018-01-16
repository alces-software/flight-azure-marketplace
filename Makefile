# Image config
IMAGE_TYPE=alces-flight-compute
IMAGE_VERSION=0.0.1-azure
IMAGE_NAME=$(IMAGE_TYPE)-$(IMAGE_VERSION)

# Libvirt/Oz config
KS=flight-compute-azure.ks.template
KS_RENDERED=/tmp/$(IMAGE_NAME).ks
TDL=centos7.tdl
TDL_RENDERED=/tmp/$(IMAGE_NAME).tdl
OZ_CFG=oz.cfg
VM_DIR=/opt/vm
QEMU_IMG_BIN=$(VM_DIR)/qemu-img
XML=domain.xml
XML_RENDERED=$(IMAGE_NAME).xml

# Azure config
STORAGE_ACCOUNT=alces
STORAGE_CONTAINER=images
RESOURCE_GROUP=alces

# Disk config
MB=$$((1024 * 1024))

all: setup build prepare convert upload

setup:
	@[ -d $(VM_DIR) ] || mkdir -p $(VM_DIR)/converted
	@cp $(TDL) $(TDL_RENDERED)
	@cp $(KS) $(KS_RENDERED)
	@sed -i -e 's,c7,$(IMAGE_NAME),g' $(TDL_RENDERED)
	@sed -i -e 's,%BUILD_RELEASE%,$(IMAGE_VERSION),g' $(KS_RENDERED)

build:
	@echo "Building image $(IMAGE_NAME)"
	oz-install -d3 -u $(TDL_RENDERED) -x /tmp/$(IMAGE_NAME).xml \
					   -p -a $(KS_RENDERED) -c $(OZ_CFG) -t 1800

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

upload:
	@echo "Uploading $(IMAGE_NAME) to blob storage"
	@az storage blob upload --account-name $(STORAGE_ACCOUNT) \
												  --container-name $(STORAGE_CONTAINER) \
													--type page \
													--file $(VM_DIR)/$(IMAGE_NAME).vhd \
													--name $(IMAGE_NAME)
	@echo "Creating new image $(IMAGE_NAME)"
	@az image create --resource-group $(RESOURCE_GROUP) \
								   --name $(IMAGE_NAME) \
									 --location uksouth \
									 --os-type Linux \
									 --source "https://$(STORAGE_ACCOUNT).blob.core.windows.net/$(STORAGE_CONTAINER)/$(IMAGE_NAME)"

clean:
	@echo "Cleaning all disk images for $(IMAGE_NAME)"
	@rm -fv $(VM_DIR)/$(IMAGE_NAME)* $(VM_DIR)/converted/$(IMAGE_NAME)*

boot:
	@echo "Booting image $(IMAGE_NAME)"
	@genisoimage -o $(VM_DIR)/$(IMAGE_NAME)-config.iso -V cidata -r -J meta-data user-data
	@cp $(XML) $(XML_RENDERED)
	@sed -i -e 's,%IMAGE_NAME%,$(IMAGE_NAME),g' \
					-e 's,%VM_DIR%,$(VM_DIR),g' \
					-e 's,%SOURCE_BRIDGE_INT%,$(PRV_BRIDGE),g' \
					$(XML_RENDERED)
	@virsh define $(XML_RENDERED)
	@virsh start $(IMAGE_NAME)
