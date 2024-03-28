# Network Boot Raspberry Pi

This project facilitates the network boot of Raspberry Pi devices using PXE boot. It automates the process of downloading necessary Raspberry Pi images from the internet, copying user files and boot files, and setting up a daemon service named `pxe.service` to listen to devices requesting boot files over the network. 

## Features
- Downloads Raspberry Pi images from the internet
- Copies user files and boot files
- Sets up a daemon service (`pxe.service`) to handle boot requests
- Creates a file system based on the MAC address of client devices
- Maintains a list of MAC addresses in `/opt/address.txt`
- Logs activities in `/var/log/macscript.log`

## Usage

### Prerequisites
- Raspberry Pi devices
- Network environment configured for PXE boot

### Installation Steps
1. Clone the repository:
    ```bash
    git clone https://github.com/nimishgj/network-boot-raspberry-pi.git
    cd network-boot-raspberry-pi
    ```

2. Make `setup.sh` executable:
    ```bash
    chmod u+x setup.sh
    ```

3. Execute `setup.sh` script:
    ```bash
    ./setup.sh
    ```

## Notes
- Ensure that the network environment is properly configured for PXE boot.
- After setup, Raspberry Pi devices should be able to boot via the network using the provided configurations.

## Contributing
Contributions are welcome! Feel free to open issues or pull requests.

