# Scytale

> In cryptography, a scytale, is a tool used to perform a transposition cipher, consisting of a cylinder with a strip of parchment
> wound around it on which is written a message. The ancient Greeks, and the Spartans in particular, are said to have used this cipher to communicate during military campaigns.
>
> [Wikipedia](https://en.wikipedia.org/wiki/Scytale)

## Docs Table of Contents

- [Why](#why)
- [PKI Basic](#pki-basics)
- [Getting Started](#getting-started)
- [Architecture](#getting-started)
- [Renewal/Deployment](#renewal-and-deployment)
- [Keys](#keys)
- Certificates
  - [Server Certificates](#server-certificates)
  - [Client Authentication Certificates](#client-authentication-certificates)
- [Certificate Signing Request](#certificate-signing-request)
- [Further Reading](#further-reading-and-reference)

## Why

First and foremost we are acting as our own [Certificate Authority](https://en.wikipedia.org/wiki/Certificate_authority) CA
to allow complete off the grid intranet. This allows us to to use whatever domain names we want.

Previously I was managing this in the same repo that way deploying various services. I think it would be better to leave
generating and deploying certificates to it's own repo. This has the benefit of keeping the private keys all in one place.

Finally this repo should act as a compendium to basic [public key infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) (PKI)
setup for intranet infrastructure.

## PKI Basics

Both the server and client certificates are signed by our Root CA. The Root CA certificate is installed on
both the client and server thus they can each validate each other against the Root CA.

## Getting Started

```bash
pip install ansible==2.9.10

# If you already have a Ansible Vault Key set its path in vars.yml otherwise
echo random_password > ~/.ansible/vault/default_key.txt
```

Configure `vars.yml` or if testing the project out leave defaults.

You can also set certificate deployments in th `hosts.yml` file.

To run the ansible play just run

**NOTE currently first pass will fail but add the private key to the vault, subsiquent runs should have not problem, will fix soon

```bash
sh ./main.sh
```

This calls

```bash
ansible-playbook --vault-password-file ~/.ansible/vault/default_key.txt -i hosts main.yml
```

## Project Architecture

This project is separated into a few different plays as we need to generate private keys and then ensure they are saved
to the vault making sure they are available for later plays from the vault and not local file system.

- private key generation
- certificate generation

What typically should happen is any downstream services should b

### Renewal and Deployment

Some services require a limit on certificate validity. Chrome and Safari usually limit this to about 365 days, Letsencrypt
certs are valid for and renew per month.

When we renew or add new certificates downstream services can be notified use a webhook.

When using a different Ansible project you can have it trigger a handler if any of the certificates or keys change. 

## Keys

While certificates should be thought as semi ephemeral (more info in [Renewal](#renewal)) keys should not change and
should be used to sign future certificates. Furthermore these private keys can (and are) password protected it's better
for us to check these into the [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) for disaster
recovery and multiple developer machines.

## Certificates

### Server Certificates

These certificates ensure when connecting to each service your connection is secured. If your client validates this certificate
the [root CA] needs to be installed on the client's host. Scytale only handles generating and renewal of the certificates
and private keys, with an optional set of hosts to install to.

Examples include

- [Docker Hosts](https://docs.docker.com/engine/security/https/)
- Reverse proxy such as
  - [Nginx]()
  - [Traefik](https://docs.traefik.io/https/tls/)
- Databases
  - [Postgres](https://www.postgresql.org/docs/9.0/ssl-tcp.html)
- Message Queues
  - [Rabbit MQ](https://www.rabbitmq.com/ssl.html)
- Email server

### Client Authentication Certificates

These certificates ensure only approved clients can connect to your services.

- [Docker](https://docs.docker.com/engine/security/certificates/)
- [Postgres](https://www.postgresql.org/docs/9.0/libpq-ssl.html

## Certificate Signing Request

> In public key infrastructure (PKI) systems, a certificate signing request (also CSR or certification request) is a message
> sent from an applicant to a certificate authority in order to apply for a digital identity certificate.
> [Wikipedia](https://en.wikipedia.org/wiki/Certificate_signing_request)

As we are acting as are own Certificate Authority we pass `ownca_*` variables to Ansible's `openssl_certificate`

### Key Usage

| Key usage extension | Description                                                                                                                                                                                                                                                                 |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Digital signature   | Use when the public key is used with a digital signature mechanism to support security services other than non-repudiation, certificate signing, or CRL signing. A digital signature is often used for entity authentication and data origin authentication with integrity. |
| Non-repudiation     | Use when the public key is used to verify digital signatures used to provide a non-repudiation service. Non-repudiation protects against the signing entity falsely denying some action (excluding certificate or CRL signing).                                             |
| Key encipherment    | Use when a certificate will be used with a protocol that encrypts keys. An example is S/MIME enveloping, where a fast (symmetric) key is encrypted with the public key from the certificate. SSL protocol also performs key encipherment.                                   |
| Data encipherment   | Use when the public key is used for encrypting user data, other than cryptographic keys.                                                                                                                                                                                    |
| Key agreement       | Use when the sender and receiver of the public key need to derive the key without using encryption. This key can then can be used to encrypt messages between the sender and receiver. Key agreement is typically used with Diffie-Hellman ciphers.                         |
| Certificate signing | Use when the subject public key is used to verify a signature on certificates. This extension can be used only in CA certificates.                                                                                                                                          |
| CRL signing         | Use when the subject public key is to verify a signature on revocation information, such as a CRL.                                                                                                                                                                          |
| Encipher only       | Use only when key agreement is also enabled. This enables the public key to be used only for enciphering data while performing key agreement.                                                                                                                               |
| Decipher only       | Use only when key agreement is also enabled. This enables the public key to be used only for deciphering data while performing key agreement.                                                                                                                               |

### Extended Key

Extended key usage further refines key usage extensions. An extended key is either critical or non-critical. If the extension is critical, the certificate must be used only for the indicated purpose or purposes. If the certificate is used for another purpose, it is in violation of the CA's policy.

If the extension is non-critical, it indicates the intended purpose or purposes of the key and may be used in finding the correct key/certificate of an entity that has multiple keys/certificates. The extension is then only an informational field and does not imply that the CA restricts use of the key to the purpose indicated. Nevertheless, applications that use certificates may require that a particular purpose be indicated in order for the certificate to be acceptable.

| Extended key                        | Enable for these key usage extensions                                        |
| ----------------------------------- | ---------------------------------------------------------------------------- |
| TLS Web server authentication       | Digital signature, key encipherment or key agreement                         |
| TLS Web client authentication       | Digital signature and/or key agreement                                       |
| Sign (downloadable) executable code | Digital signature                                                            |
| Email protection                    | Digital signature, non-repudiation, and/or key encipherment or key agreement |
| IPSEC End System (host or router)   | Digital signature and/or key encipherment or key agreement                   |
| IPSEC Tunnel                        | Digital signature and/or key encipherment or key agreement                   |
| IPSEC User                          | Digital signature and/or key encipherment or key agreement                   |
| Timestamping                        | repudiation                                                                  |

---

Examples of required key usage extensions

| Application         | Required key usage extensions |
| ------------------- | ----------------------------- |
| SSL Client          | Digital signature             |
| SSL Server          | Key encipherment              |
| S/MIME Signing      | Digital signature             |
| S/MIME Encryption   | Key encipherment              |
| Certificate Signing | Certificate signing           |
| Object Signing      | Digital signature             |

Text and Chartfrom [HCL](https://help.hcltechsw.com/domino/11.0.0/conf_keyusageextensionsandextendedkeyusage_r.html)

## Further Reading and Reference

- [Running your own Ansible Driven CA](https://www.tikalk.com/posts/2016/10/30/Running-Your-Own-Ansible-Driven-CA/)
