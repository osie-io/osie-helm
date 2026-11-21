<p align="center">
  <img alt="OSIE" src=".github/assets/osie-logo-light.svg#gh-light-mode-only" width="180">
  <img alt="OSIE" src=".github/assets/osie-logo-dark.svg#gh-dark-mode-only" width="180">
</p>

<h1 align="center">OSIE Helm chart</h1>

<p align="center">
  <strong>The OpenStack dashboard and billing system, on Kubernetes</strong><br>
  The <code>osie/osie</code> chart, published at helm.osie.io
</p>

<p align="center">
  <a href="https://github.com/osie-io/osie-helm/actions/workflows/release.yml"><img alt="Release" src="https://github.com/osie-io/osie-helm/actions/workflows/release.yml/badge.svg"></a>
  <a href="https://helm.osie.io/index.yaml"><img alt="Chart version" src="https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fhelm.osie.io%2Findex.yaml&query=%24.entries.osie%5B0%5D.version&label=chart&color=4F52C9"></a>
  <a href="LICENSE"><img alt="License: GPL-3.0" src="https://img.shields.io/badge/license-GPL--3.0-4F52C9"></a>
</p>

<p align="center">
  <a href="#install"><strong>Install</strong></a>
  &nbsp;·&nbsp;
  <a href="#configuration">Configuration</a>
  &nbsp;·&nbsp;
  <a href="#exposing-osie-with-the-gateway-api">Gateway API</a>
  &nbsp;·&nbsp;
  <a href="#mongodb-and-rabbitmq-over-tls">TLS to MongoDB and RabbitMQ</a>
  &nbsp;·&nbsp;
  <a href="#upgrading-from-the-bundled-mongodb-rabbitmq-or-keycloak">Upgrading from bundled services</a>
</p>

<br>

> [!IMPORTANT]
> Running the MongoDB, RabbitMQ or Keycloak bundled with chart 26.8.2 or earlier? Read
> [Upgrading from the bundled MongoDB, RabbitMQ or Keycloak](#upgrading-from-the-bundled-mongodb-rabbitmq-or-keycloak)
> before you upgrade.

## About

[OSIE](https://osie.io) is the dashboard and billing system for OpenStack clouds. This chart deploys
its three components:

| Component | Runs as | What it is |
|---|---|---|
| `osie-api` | StatefulSet | the API, the scheduled jobs and billing |
| `osie-ui` | Deployment | the client portal, at `/` |
| `osie-admin` | Deployment | the admin dashboard, at `/osie_admin/` |

The chart deploys only OSIE. MongoDB, RabbitMQ and, when you use one, the identity provider run
outside it. [osie/deployment](https://github.com/osie/deployment/tree/main/kubernetes) has manifests
for the Percona MongoDB and RabbitMQ operators.

## Requirements

- Kubernetes and Helm 3 or 4
- a MongoDB replica set and a RabbitMQ that the cluster can reach
- an ingress controller, or a Gateway API controller, and a DNS name pointing at it
- an OSIE license key
- optionally an OpenID Connect identity provider; without one, users sign in with OSIE's own accounts

## Install

Add the repository:

```bash
helm repo add osie https://helm.osie.io
helm repo update
```

Write a `values.yaml`. This one assumes [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start),
[cert-manager](https://cert-manager.io/docs/installation/) with a ClusterIssuer called `letsencrypt`,
and MongoDB and RabbitMQ from the operator manifests in osie/deployment:

```yaml
license:
  key: "<your license key>"

global:
  ingress:
    enabled: true
    hostname: "osie.mycompany.com"
    ingressClassName: "nginx"
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt
    tls: true
  # Leave out to sign in with OSIE's own accounts
  oauth2:
    issuerUri: "https://login.mycompany.com/realms/osie"

externalMongodb:
  hosts: "mongodb-rs0"
  database: osie
  existingSecret: mongodb-users
  existingSecretUsernameKey: MONGODB_DATABASE_ADMIN_USER
  existingSecretPasswordKey: MONGODB_DATABASE_ADMIN_PASSWORD

externalRabbitmq:
  host: rabbitmq
  existingSecret: rabbitmq-default-user
  existingSecretUsernameKey: username
  existingSecretPasswordKey: password
```

Install it:

```bash
helm install osie osie/osie -n osie --create-namespace -f values.yaml
```

Once it is up, the pods look like this:

```
osie-admin-6859d96764-2rxtk   1/1     Running   0          18m
osie-admin-6859d96764-tn5lw   1/1     Running   0          18m
osie-api-0                    1/1     Running   0          18m
osie-api-1                    1/1     Running   0          15m
osie-ui-5b85f6586c-4dk2p      1/1     Running   0          18m
osie-ui-5b85f6586c-tm8gq      1/1     Running   0          18m
```

The [installation guide](https://osie.io/docs/operators-manual/kubernetes-install/) covers the full
install.

## Configuration

The settings most installs touch. [values.yaml](charts/osie/values.yaml) documents every option.

| Value | Purpose |
|---|---|
| `license.key` | the OSIE license key |
| `global.ingress` | hostname, ingress class, annotations and TLS for one Ingress per component |
| `global.gateway` | HTTPRoutes for the Gateway API instead, see [below](#exposing-osie-with-the-gateway-api) |
| `global.baseUrl` | the public URL when OSIE is exposed some other way |
| `global.oauth2` | `issuerUri`, `clientId`, `audience` and `logoutUrl` of an OpenID Connect identity provider |
| `adminApi.oauth2` | the issuers and clients trusted on the admin API (`/admin_api/v1`) |
| `externalMongodb` | `hosts` (required), database, credentials from a Secret, TLS |
| `externalRabbitmq` | `host` (required), vhost, credentials from a Secret, TLS |
| `encryption.bcrypt` | the password secret, or an existing Secret holding it |
| `smtp` | the mail server for the email OSIE sends |
| `api`, `ui`, `admin` | per component: replicas, image, resources, autoscaling, scheduling, Ingress and Gateway overrides, extra volumes and environment |

## Exposing OSIE with the Gateway API

Instead of `global.ingress`, OSIE can be exposed with the [Gateway API](https://gateway-api.sigs.k8s.io/)
on clusters running a Gateway controller such as [kgateway](https://kgateway.dev), Envoy Gateway or
Istio. The chart creates one `HTTPRoute` per component. The `GatewayClass`, the `Gateway` and its TLS
certificates are yours to manage.

You need:
- the Gateway API CRDs and a Gateway controller
- a `Gateway` whose listener allows routes from the release namespace
- your DNS name pointing at the Gateway address

```yaml
global:
  gateway:
    enabled: true
    hostname: "osie.mycompany.com"
    parentRefs:
      - name: osie-gateway
        namespace: gateway-system
        sectionName: https
    # Set when the Gateway listener terminates TLS, so OSIE advertises its URLs as https
    tls: true
```

Per component, `api.gateway`, `ui.gateway` and `admin.gateway` accept `hostname`, `paths`,
`pathType`, `filters` and `timeouts`, plus a `parentRefs` override to attach a component to a
different Gateway.

TLS works differently than with an Ingress. cert-manager issues certificates for the `Gateway`, not
for routes, so `global.gateway.annotations` land on the `HTTPRoute`s, where a
`cert-manager.io/cluster-issuer` does nothing. Annotate your `Gateway` instead, give its listener a
`tls.certificateRefs` secret, and run cert-manager with `config.enableGatewayAPI=true`. If you solve
ACME HTTP-01 challenges, use a `gatewayHTTPRoute` solver in the issuer. `global.gateway.tls` only
decides whether OSIE advertises its URLs as https.

## MongoDB and RabbitMQ over TLS

Set `tls.enabled` on `externalMongodb` and `externalRabbitmq`. When the servers present a certificate
from a private CA, point `caConfigMap` (or `caSecret`) and `caKey` at a PEM bundle holding that CA.
The chart mounts it into the API and its `wait-for-db` init container. The API trusts it only for
those connections, so public endpoints keep the default trust store.

```yaml
externalMongodb:
  hosts: "mongodb-0.db.mycompany.com"
  port: 27017
  database: osie
  extraQueryParams: "authSource=admin&replicaSet=rs0"
  existingSecret: osie-mongodb-user
  existingSecretUsernameKey: username
  existingSecretPasswordKey: password
  tls:
    enabled: true
    caConfigMap: mycompany-trust-bundle
    caKey: ca-certificates.crt

externalRabbitmq:
  host: rabbitmq.mycompany.com
  port: 5671
  vhost: osie
  existingSecret: osie-rabbitmq-user
  existingSecretUsernameKey: username
  existingSecretPasswordKey: password
  tls:
    enabled: true
    caConfigMap: mycompany-trust-bundle
    caKey: ca-certificates.crt
```

`tls.enabled` alone, with no CA, trusts the JVM's default CAs. Only the AMQP port has to be reachable;
the RabbitMQ management port is never used.

## Upgrading from the bundled MongoDB, RabbitMQ or Keycloak

Chart versions up to 26.8.2 bundled MongoDB, RabbitMQ and Keycloak, and turned them on by default.
26.8.3 and later no longer do. They refuse to upgrade a release that still runs them, before anything
changes, because Helm would delete them with their data.

Move the release first with
[migrate-bundled](https://github.com/osie/deployment/tree/main/kubernetes/migrate-bundled), on chart
26.8.2. It moves the data onto operator-managed services in one maintenance window and writes the
settings into your values file. Then upgrade with that values file.

The check reads the cluster, which tools that only render the chart cannot do (Argo CD,
`helm template`). There the chart still requires `externalMongodb.hosts` and `externalRabbitmq.host`,
which a release on the bundled services does not have, but it cannot see a bundled Keycloak. With
Argo CD, migrate before you move the release to this chart version.

## Documentation

- [Installing OSIE on Kubernetes](https://osie.io/docs/operators-manual/kubernetes-install/)
- [values.yaml](charts/osie/values.yaml), every option with its default
- [osie/deployment](https://github.com/osie/deployment), operator manifests for MongoDB and RabbitMQ, and the Docker Compose install

## License

[GPL-3.0](LICENSE)
