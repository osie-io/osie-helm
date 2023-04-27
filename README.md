## Helm chart for deploying [osie.io](https://osie.io) - the OpenStack dashboard and billing system
By default this chart also installs [Keycloak](https://www.keycloak.org) which is the default Identity provider that's recommended with osie. It's being deployed by the subchart  [bitnami/keycloak](https://github.com/bitnami/charts/tree/main/bitnami/keycloak/) 
### Add the Helm repository
```
helm repo add osie https://helm.osie.io
helm repo update
```

### Install the chart
Default prerequisites (else adapt [values.yaml](charts/osie/values.yaml))
- [cert-manager](https://cert-manager.io/docs/installation/) with a [ClusterIssuer](https://cert-manager.io/docs/configuration/acme/) called `letsencrypt`
- [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start) controller
- a default `StorageClass`
- `<your-domain>` and `auth.<your-domain>` configured in your DNS pointing to your ingress IP

Then the deployment can be as easy as:
```
helm install osie osie/osie --set global.ingress.hostname=osie.mydomain.com
```
See [values.yaml](charts/osie/values.yaml) for more configuration options.

Typical pods will look like this
```
osie-admin-6859d96764-2rxtk   1/1     Running   0          18m
osie-admin-6859d96764-tn5lw   1/1     Running   0          18m
osie-api-0                    1/1     Running   0          18m
osie-api-1                    1/1     Running   0          15m
osie-keycloak-0               1/1     Running   0          8m48s
osie-keycloak-1               1/1     Running   0          42s
osie-keycloak-2               1/1     Running   0          42s
osie-mongodb-0                1/1     Running   0          18m
osie-mongodb-1                1/1     Running   0          17m
osie-mongodb-2                1/1     Running   0          17m
osie-mongodb-arbiter-0        1/1     Running   0          18m
osie-postgresql-primary-0     1/1     Running   0          18m
osie-postgresql-read-0        1/1     Running   0          18m
osie-rabbitmq-0               1/1     Running   0          8m39s
osie-redis-master-0           1/1     Running   0          8m48s
osie-redis-replicas-0         1/1     Running   0          7m14s
osie-redis-replicas-1         1/1     Running   0          7m59s
osie-redis-replicas-2         1/1     Running   0          8m47s
osie-ui-5b85f6586c-4dk2p      1/1     Running   0          18m
osie-ui-5b85f6586c-tm8gq      1/1     Running   0          18m
```