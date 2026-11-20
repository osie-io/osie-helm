## Helm chart for deploying [osie.io](https://osie.io) - the OpenStack dashboard and billing system
The chart runs the osie API, client portal and admin. MongoDB, RabbitMQ and the identity provider run
outside it, for example from the operators in [osie/deployment](https://github.com/osie/deployment/tree/main/kubernetes).

### Upgrading a release that runs the bundled MongoDB, RabbitMQ or Keycloak
Chart versions up to 26.8 bundled them, and turned them on by default. This version no longer does, and
it refuses to upgrade a release that still runs them, before anything changes, because Helm would
delete them with their data. Move the release first with
[migrate-bundled](https://github.com/osie/deployment/tree/main/kubernetes/migrate-bundled), on chart 26.8,
then upgrade with the values it writes merged into yours.

The check reads the cluster, which tools that only render the chart cannot do (Argo CD, `helm template`).
There the chart still requires `externalMongodb.hosts` and `externalRabbitmq.host`, which a release on the
bundled services does not have, but it cannot see a bundled Keycloak. With Argo CD, migrate before you
move the release to this chart version.

### Full documentation

[Osie installation documentation](https://osie.io/docs/operators-manual/kubernetes-install/)

### Add the Helm repository
```
helm repo add osie https://helm.osie.io
helm repo update
```

### Install the chart
The following values expect these prerequisites (else adapt [values.yaml](charts/osie/values.yaml))
- [cert-manager](https://cert-manager.io/docs/installation/) with a [ClusterIssuer](https://cert-manager.io/docs/configuration/acme/) called `letsencrypt`
- [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start) controller
- a MongoDB replica set and a RabbitMQ, for example the Percona and RabbitMQ operator manifests in
  [osie/deployment](https://github.com/osie/deployment/tree/main/kubernetes)
- `<your-domain>` configured in your DNS pointing to your ingress IP

**values.yaml**
```yaml
global:
  ingress:
    enabled: true
    hostname: "osie.mycompany.com"
    ingressClassName: "nginx"
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt
    tls: true
  # Leave out to sign in with osie's own accounts
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
```
helm install osie osie/osie -f values.yaml 
```
See [values.yaml](charts/osie/values.yaml) for more configuration options.

### Exposing osie with the Gateway API
Instead of `global.ingress`, osie can be exposed with the [Gateway API](https://gateway-api.sigs.k8s.io/)
on clusters running a Gateway controller such as [kgateway](https://kgateway.dev), Envoy Gateway or Istio.
The chart creates one `HTTPRoute` per component; the `GatewayClass`, the `Gateway` and its TLS
certificates are yours to manage.

Prerequisites:
- Gateway API CRDs and a Gateway controller
- a `Gateway` the routes can attach to, whose listener allows routes from the release namespace
- `<your-domain>` in your DNS pointing to the Gateway address

**values.yaml**
```yaml
global:
  gateway:
    enabled: true
    hostname: "osie.mycompany.com"
    parentRefs:
      - name: osie-gateway
        namespace: gateway-system
        sectionName: https
    # Set when the Gateway listener terminates TLS, so osie advertises its URLs as https
    tls: true
```

Per component, `api.gateway`, `ui.gateway` and `admin.gateway` accept `hostname`, `paths`,
`pathType`, `filters` and `timeouts`, plus a `parentRefs` override to attach a component to a
different Gateway.

TLS works differently than with ingress. cert-manager issues certificates against the `Gateway`, not
against routes, so `global.gateway.annotations` land on the `HTTPRoute`s and a
`cert-manager.io/cluster-issuer` there does nothing. Annotate your `Gateway` instead, give its
listener a `tls.certificateRefs` secret, run cert-manager with `config.enableGatewayAPI=true`, and
if you solve ACME HTTP-01 challenges use a `gatewayHTTPRoute` solver in the issuer rather than the
default ingress solver. `global.gateway.tls` only decides whether osie advertises its URLs as https.


### External MongoDB and RabbitMQ over TLS
Set `tls.enabled` on `externalMongodb` and `externalRabbitmq`. When the servers present a
certificate from a private CA, point `caConfigMap` (or `caSecret`) and `caKey` at a PEM bundle
holding that CA. The chart mounts it into the API and its `wait-for-db` init container. The API trusts
it only for that connection, so public endpoints keep the default trust store.

**values.yaml**
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

Typical pods will look like this
```
osie-admin-6859d96764-2rxtk   1/1     Running   0          18m
osie-admin-6859d96764-tn5lw   1/1     Running   0          18m
osie-api-0                    1/1     Running   0          18m
osie-api-1                    1/1     Running   0          15m
osie-ui-5b85f6586c-4dk2p      1/1     Running   0          18m
osie-ui-5b85f6586c-tm8gq      1/1     Running   0          18m
```
