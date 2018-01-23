<div align="center">
    <h2>Alces Flight on Azure Marketplace</h2>
    <p align="center">
        <p>Scripts and templates that form the Alces Flight Azure Marketplace offering</p>
    </p>
</div>

# Prerequisites ✅

- Standard Alces Libvirt host setup
- A clone of this repository
- Azure command-line interface configured
- `qemu-img` version `2.9.0` or later installed to `$VM_DIR/qemu-img`

# Building an image 🛠

## Image builder config 📝

### Oz configuration

The Oz configuration file (`oz.cfg`) contains some configuration specific to the host, specifically:

- `output_dir` - The directory to store the built VM. This is also set in `Makefile` as `VM_DIR`
- `bridge_name` - The Libvirt interface to bridge the build machines on. Typically this is `virbr0`
- `cpus` - Set the number of CPU cores to assign the build machine. If you are building the image on a larger machine, you may wish to assign more CPU cores to (possibly) speed up the build
- `memory` - Set the amount of memory to assign to the build machine

### `Makefile` configuration

Configuration can be found in both `Makefile` and `oz.cfg`. If using a non-standard setup, ensure that the interface name is correct in `oz.cfg`. Optionally, more CPU cores and memory can be provided to the build machine if they are available on the host - speeding up the process.

In addition to the Oz configuration - the `Makefile` contains some settings that can be tweaked depending on the Libvirt host - most importantly:

* `IMAGE_VERSION` - adjust the image version or tag
* `VM_DIR` - the directory used to store virtual machine images. This directory must have enough space available to store several image files

There is also some Azure command-line configuration required in the `Azure config` section - the following details are required in order to successfully upload an image:

- `STORAGE_ACCOUNT` - The name of the storage account used to store the image in. This storage account should previously have been created using either the command-line tools or the Azure portal
- `STORAGE_CONTAINER` - The name of the blob storage container. The container should previously have been created using either the command-line tools or the Azure portal
- `RESOURCE_GROUP` - The name of the resource group `$STORAGE_ACCOUNT` belongs to

## Create, and upload an image 🚀

The build process can be performed in two ways:

- All-in-one create, prepare and upload
- Run each stage separately

### All-in-one

Check the configuration in `Makefile`, particularly the version number. Once you are happy with the configuration - use `make` to create, prepare and upload your image to Azure:

```bash
make
```

The process can take quite some time - during this time it will:

- Render the kickstart file and prepare various directories for the build process
- Build the image using the rendered kickstart file, this will generate a QCOW2 image
- Prepare the QCOW2 image, running `sysprep` and converting the image to RAW format
- Convert the image from RAW format to VHD using the `qemu-img` binary installed to `$VM_DIR`
- Upload the VHD image to Azure blob storage, then create a new image

### Separate stages

The build process can also be run in separate stages, in the order as follows:

```bash
make setup && make build
make prepare
make convert
make upload
```

# CI 🚨

Travis CI runs automated tests against this repository, the tests check the validity of the Azure marketplace templates using the open-source Azure validation tests. It is important that these tests are passing before submitting templates to the Azure Marketplace, as the same tests will be run by the certification team.

# Extras

## `clean`/`clean-all`

The `Makefile` contains two clean targets:

- `clean` - Remove all images relating to the current `IMAGE_VERSION` set in the `Makefile`
- `clean-all` Remove all images relating to the current `IMAGE_TYPE` set in the `Makefile`
