IMAGE_NAME=flight-compute-$$RANDOM
KICKSTART=flight-compute-azure.ks.template
TDL=centos7.tdl
OZ_CFG=oz.cfg
VM_DIR=/opt/vm

all: setup image

setup:
	@[ -d $(VM_DIR) ] || mkdir -p $(VM_DIR)/converted

image:
	@echo "Building image $(IMAGE_NAME)"
	oz-install -d3 -u $(TDL) -x /tmp/$(IMAGE_NAME).xml \
					   -p -a $(KICKSTART) -c $(OZ_CFG) -t 1800
