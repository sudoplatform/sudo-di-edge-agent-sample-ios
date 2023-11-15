# Sudo DI Edge Agent Sample App for iOS

## Overview

This project provides examples for interacting with the Sudo DI Edge Agent iOS SDK on the [Sudo Platform](https://sudoplatform.com/).

## Version Support

| Technology             | Supported version |
| ---------------------- | ----------------- |
| iOS Deployment Target  | 16.0+             |
| Swift language version | 5.0               |
| Xcode version          | 14.0+             |

## Getting Started

To build this app you first need to obtain test keys and a client config file and add them to the project.

1. Contact the Sudo Platform for access to the Edge Agent SDK [partners@sudoplatform.com](mailto:partners@sudoplatform.com).

2. Follow the steps in the [Getting Started guide](https://docs.sudoplatform.com/guides/getting-started) and in [User Registration](https://docs.sudoplatform.com/guides/users/registration) to obtain a config file (sudoplatformconfig.json) and a TEST registration key, respectively

3. Place both files in the following location with these names:

```
${PROJECT_DIR}/config/sudoplatformconfig.json
${PROJECT_DIR}/config/register_key.private
```

4. Create a text file containing the test registration key ID at the following location:

```
${PROJECT_DIR}/config/register_key.id
```

5. Optionally, you can add a different "ledger" to the application by replacing the genesis file in `Resources` folder. By default, this example app uses the indicio testnet, however you can change this if you're testing an DI ecosystem with a different ledger.

## Running the app

App will build and run on the simulator out of the box, and physical devices will require some minor setup. It is recommended that this app is ran on a physical device to use the camera to scan QR codes.

## Running on a physical device:

* Change the bundle identifier, e.g. "com.yourCompany.sudoDIEdgeAgentExample" so that Xcode can automatically create provisioning profiles. The existing bundle ID is owned by the sudo platform and cannot be used on another developer account.
* Set the development team. From the project navigator, choose the "SudoDIEdgeAgentExample" target and select the "Signing and Capabilities" tab. You must be signed into your developer account through Xcode (About -> Preferences -> Account tab).
* Note: If using a personal account, the app may fail to run on the device if it's not trusted. In the settings app navigate to General -> Device Management -> Select developer account, e.g. "Apple development: yourEmail@yourDomain.com". From this screen you can trust the app and attempt to run again.

## More Documentation

Refer to the following documents for more information:

- [Getting Started on Sudo Platform](https://docs.sudoplatform.com/guides/getting-started)

## Issues and Support

File issues you find with this sample app in this Github repository. Ensure that you do not include any Personally Identifiable Information (PII), API keys, custom endpoints, etc. when reporting an issue.

For general questions about the Sudo Platform please contact [partners@sudoplatform.com](mailto:partners@sudoplatform.com)
