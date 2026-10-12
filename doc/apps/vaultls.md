# VaulTLS and client certificates (mTLS)

## Table of content

* [What is it for?](#what-is-it-for)
* [How it works in the seedbox](#how-it-works-in-the-seedbox)
* [Installation](#installation)
* [Protect a service with mTLS](#protect-a-service-with-mtls)
  * [Example: Home Assistant, on your LAN and from outside](#example-home-assistant-on-your-lan-and-from-outside)
* [Revoke a certificate](#revoke-a-certificate)
* [Use another Certificate Authority](#use-another-certificate-authority)
* [Troubleshooting](#troubleshooting)

## What is it for?

With **mTLS**, a service is only reachable by devices which own a **client certificate** that you created. Without it, the connection is refused before anything of the service is reached: no login page, nothing to attack.

It suits a service which must be reachable from the Internet without any action from the user (no VPN to start), by a few known devices. The typical case is the mobile application of Home Assistant, which reports your location in the background.

[VaulTLS](https://github.com/7ritn/VaulTLS) is a web interface to create and manage these certificates. It runs your own Certificate Authority (CA).

> VaulTLS holds the private keys of the certificates it creates, and their passwords. It is only reachable from your private networks by default (``internalOnly``): **never publish it on the Internet**.

## How it works in the seedbox

* A Traefik rule with ``mtls: true`` (or ``tls.options: mtls@file`` in your own Traefik files) requires a client certificate.
* ``run-seedbox.sh`` generates the ``mtls`` TLS option of Traefik with your Certificate Authorities: the one of VaulTLS when the service is enabled, and the files you place in ``services/traefik/custom/mtls/``.
* The check is done by Traefik itself during the TLS handshake, before any middleware. A client without a valid certificate cannot even open the connection.
* If a rule requires mTLS but no Certificate Authority is found, ``run-seedbox.sh`` stops with an error: a rule which is supposed to be protected is never applied without its protection.

The client must talk to Traefik directly: mTLS does not work through a proxy which terminates TLS before Traefik, such as the proxy of Cloudflare (see [Troubleshooting](#troubleshooting)).

mTLS is decided **for a host**. A host cannot require a certificate from outside and none from your LAN: use two hosts for that, as in the [example below](#example-home-assistant-on-your-lan-and-from-outside).

## Installation

Enable the service in ``config.yaml``, then create its environment file:

```yaml
services:
  vaultls:
```

```sh
tools/sync-templates.sh
```

Set ``VAULTLS_API_SECRET`` in ``services/vaultls/custom/service.env`` (generate it with ``openssl rand -base64 32``), then:

```sh
./run-seedbox.sh
```

Open ``https://vaultls.yourdomain.com`` (from your LAN) and do the first setup: your Certificate Authority is created at this step.

Then, for each device:

1. Create a **client** certificate in VaulTLS and download it (``.p12`` file). Set a password on it: the file contains the private key.
2. Install it on the device: in the certificates of the system on a phone, in the browser or the system keychain on a computer.

Finally, run ``./run-seedbox.sh`` again, so that Traefik gets the Certificate Authority which was just created.

## Protect a service with mTLS

For a service of the seedbox, add ``mtls: true`` on its rule in ``config.yaml``:

```yaml
services:
  sonarr:
    rules:
      - mtls: true
```

For your own Traefik files (``services/traefik/custom/rules/``), use the ``mtls`` TLS option on the router:

```yaml
http:
  routers:
    myservice:
      rule: 'Host(`myservice.{{ env "TRAEFIK_DOMAIN" }}`)'
      service: myservice
      entryPoints:
        - secure
      tls:
        options: mtls@file
```

> Check first that the application you use supports client certificates: browsers do, but not all mobile applications.

### Example: Home Assistant, on your LAN and from outside

The goal: no certificate needed at home, a certificate required everywhere else. Home Assistant runs on another machine of the LAN, so its rules are in ``services/traefik/custom/rules/homeassistant.yaml``, with one host for each case:

```yaml
http:
  routers:
    # At home: home.yourdomain.com, only reachable from your private networks
    homeassistant:
      rule: 'Host(`home.{{ env "TRAEFIK_DOMAIN" }}`)'
      service: homeassistant
      entryPoints:
        - secure
      middlewares:
        - internal-only@file
    # Everywhere else: ha.yourdomain.com, client certificate required
    homeassistant-external:
      rule: 'Host(`ha.{{ env "TRAEFIK_DOMAIN" }}`)'
      service: homeassistant
      entryPoints:
        - secure
      tls:
        options: mtls@file
  services:
    homeassistant:
      loadBalancer:
        servers:
          - url: "http://192.168.0.93:8123"
```

In the mobile application of Home Assistant, set ``https://home.yourdomain.com`` as internal URL (used on your home Wi-Fi) and ``https://ha.yourdomain.com`` as external URL, and select the client certificate when the application asks for it.

Both hosts must resolve to your server: ``home`` with your local DNS, ``ha`` with your public DNS. If your public DNS is Cloudflare, set the ``ha`` record to "DNS only".

## Revoke a certificate

**Traefik does not check revocation lists (CRL).** Revoking a certificate in VaulTLS is not enough: Traefik keeps accepting it until it expires.

So, when a device is lost or stolen:

1. Protect what the certificate gives access to: the service still has its own authentication, change the passwords used on this device.
2. Replace your Certificate Authority: create a new one in VaulTLS, create new certificates for your other devices, then run ``./run-seedbox.sh``. Certificates signed by the old one are refused from this moment.

With a few devices, this takes some minutes. To limit the consequences of a forgotten certificate, give them a short validity (one year for example): VaulTLS can notify you by email before they expire.

> Traefik plugins exist to check revocation lists. None is bundled: such a plugin becomes a part of your security, review it before using it.

## Use another Certificate Authority

VaulTLS is not required. Place the certificate of any Certificate Authority (``.crt`` or ``.pem`` file, without its private key) in ``services/traefik/custom/mtls/`` and run ``./run-seedbox.sh``. All files of this directory are trusted, in addition to the one of VaulTLS if it is enabled.

## Troubleshooting

| Symptom | Cause and solution |
|---------|--------------------|
| ``run-seedbox.sh`` stops with ``Some Traefik rules require a client certificate (mtls) but no Certificate Authority was found`` | VaulTLS is not enabled or its first setup is not done, and ``services/traefik/custom/mtls/`` is empty. If VaulTLS is set up, the script cannot read its Certificate Authority (``$HOST_CONFIG_PATH/vaultls/ca/ca-tls.cert``): copy it to ``services/traefik/custom/mtls/`` |
| Cloudflare error page ``520`` (or another ``52x`` error), even with the certificate installed | The DNS record of the host uses the proxy of Cloudflare (orange cloud). Cloudflare ends the TLS connection of your device, then connects to Traefik without your client certificate, so Traefik refuses it. Set the record to "DNS only" (grey cloud). Your public IP becomes visible for this host, which is protected by the client certificate |
| The browser or the application fails to connect, without any error page | Expected without a valid certificate: the connection is refused during the TLS handshake. Check that the certificate is installed on the device and signed by your current Certificate Authority |
| A new certificate is refused after replacing the Certificate Authority | Run ``./run-seedbox.sh``: Traefik only gets the Certificate Authority when the script runs |
| ``421 Misdirected Request`` in a browser | The browser reused a connection opened for another host of your domain. Reload the page, or close the tabs of the other host |
