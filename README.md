<div align="center">
    <h2>Alces Flight on Azure Marketplace</h2>
    <p align="center">
        <p>Scripts and templates that form the Alces Flight Azure Marketplace offering</p>
    </p>
</div>

# Prerequisites ✅

* Standard Alces Libvirt host setup
* A clone of this repository
* Azure command-line interface configured

# Building an image 🛠

## Image builder config 📝

Configuration can be found in both `Makefile` and `oz.cfg`. If using a non-standard setup, ensure that the interface name is correct in `oz.cfg`. Optionally, more CPU cores and memory can be provided to the build machine if they are available on the host - speeding up the process.

In addition to the Oz configuration - the `Makefile` contains some settings that can be tweaked depending on the Libvirt host - most importantly:

* `IMAGE_VERSION` - adjust the image version or tag
* `VM_DIR` - the directory used to store virtual machine images. This directory must have enough space available to store several image files

## Create, and upload an image 🚀

TL;DR:

```
make IMAGE_VERSION="my-image-version"
```
