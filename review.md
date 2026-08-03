### Qu'est-ce qu'Istio ?

**Istio** est un **Service Mesh** (réseau de services) open-source.

Lorsque le nombre de microservices augmente dans Kubernetes, gérer la communication, la sécurité et la visibilité directement dans le code des applications devient un véritable cauchemar. Istio résout ce problème en injectant un proxy léger (**Envoy**) à côté de chaque pod (pattern *Sidecar*). Cela permet de séparer complètement la gestion du réseau, du chiffrement et de la télémétrie du code applicatif.

---

### Utilité principale : Pourquoi utiliser Istio ?

1. **Gestion avancée du trafic (Traffic Routing)**
* Réaliser des déploiements **Canary** ou **Blue-Green** en divisant le trafic par pourcentage (ex: 90% vers la `v1`, 10% vers la `v2`).
* Configurer des retries automatiques, du rate-limiting, des timeouts ou de la simulation de pannes (*Chaos Engineering*) sans modifier une ligne de code.


2. **Sécurité Zero-Trust & mTLS**
* Chiffre automatiquement toutes les communications entre pods via du **mTLS (Mutual TLS)**.
* Offre un contrôle d'accès fin (RBAC) pour définir précisément *quel* microservice a le droit de communiquer avec *quel autre*.


3. **Observabilité globale**
* Génère des métriques, des logs et du tracing distribué (s'intègre nativement avec Prometheus, Grafana, Jaeger et Kiali) pour visualiser la cartographie exacte du trafic en temps réel.



---

### Les composants clés : `istiod` et Istio Ingress

```text
                       [ Internet Public ]
                                |
                                v
                   [ Istio Ingress Gateway ]
                  (Proxy d'entrée - IP Public)
                                |
             +------------------+------------------+
             |                                     |
             v (mTLS)                              v (mTLS)
      [ Pod: Service A ]                    [ Pod: Service B ]
      (Sidecar Envoy)                       (Sidecar Envoy)
             ^                                     ^
             |     (Distribue Configs & Certs)     |
             +-----------------+-------------------+
                               |
                           [ istiod ]
                         (Control Plane)

```

#### 1. Qu'est-ce que `istiod` ?

`istiod` est le **Control Plane** (le cerveau) d'Istio.

* **Traducteur de configuration :** Il convertit les objets Kubernetes Istio (comme `VirtualService`, `Gateway`, `DestinationRule`) en configurations compréhensibles par les proxys Envoy.
* **Autorité de Certification (CA) :** Il génère et renouvelle dynamiquement les certificats TLS de chaque pod pour assurer le mTLS automatique.
* **Service Discovery :** Il suit l'état des Pods et des services dans le cluster pour indiquer aux proxys où envoyer le trafic.

> **Point clé pour l'entretien :** `istiod` ne touche **jamais** aux données ou au trafic applicatif direct (*Data Plane*). Il s'occupe uniquement du contrôle, de la sécurité et des configurations.

#### 2. Qu'est-ce que l'Istio Ingress Gateway ?

L'**Istio Ingress Gateway** est le **point d'entrée principal** du trafic externe vers l'intérieur du cluster Kubernetes.

* **Proxy de bordure (Edge Proxy) :** C'est un pod Envoy spécialisé placé à la frontière du cluster, généralement rattaché à un Load Balancer AWS (ALB/NLB).
* **Terminaison TLS & Routage :** Il gère la terminaison HTTPS, vérifie les certificats et redirige les requêtes entrantes vers les bons microservices internes en fonction du domaine, de l'URL ou des headers.
* **Gestion centralisée :** Comme il s'agit d'un proxy Envoy piloté par `istiod`, il se configure directement avec les CRDs Istio (`Gateway` + `VirtualService`) plutôt qu'avec les objets Ingress Kubernetes standards.

---

### 💡 Le pitch rapide pour l'entretien (30 secondes)

> *"**Istio** est un Service Mesh qui sécurise, oriente et surveille les communications microservices via des sidecars Envoy. **`istiod`** est le composant du Control Plane qui distribue la configuration et gère les certificats mTLS. L'**Istio Ingress Gateway** est le proxy Envoy d'entrée du cluster qui réceptionne le trafic externe avant de le redistribuer de manière sécurisée dans le mesh."*



-------------------------

Voici un guide clair, synthétique et précis pour expliquer l'utilisation de **Falco** et **Wazuh** dans une architecture Cloud / Kubernetes, parfait pour briller en entretien.

---

### 1. Falco (Runtime Security en Temps Réel)

#### **Rôle**

Falco est le détective de sécurité du **noyau Linux / Kubernetes**. Il surveille en temps réel le comportement des conteneurs au niveau système (Kernel System Calls) pour détecter toute anomalie ou attaque active.

#### **Composants Clés**

* **Kernel Module / eBPF Probe :** Intercepte les appels système (`syscalls`) du noyau Linux directement à la source.
* **Falco Engine :** Analyse ces événements en temps réel à l'aide d'un moteur de règles préconfiguré ou personnalisé.
* **Ruleset :** Fichiers YAML qui définissent les comportements suspects (ex: ouverture d'un shell dans un pod, modification d'un fichier sensible dans `/etc/`, exécution d'un binaire inattendu).
* **Falco Sidekick :** Composant essentiel pour transférer et formater les alertes générées par Falco vers des destinations externes.

#### **Cas d'usage typiques**

* Détection d'un shell interactif ouvert par un attaquant dans un pod de production.
* Détection de processus non autorisés ou d'escalade de privilèges.

---

### 2. Wazuh (SIEM & XDR / Conformité & Sécurité Système)

#### **Rôle**

Wazuh est un **SIEM (Security Information and Event Management) et XDR open source**. Il agrège, analyse et centralise les logs d'infrastructures, d'OS, de nœuds Kubernetes et de services cloud pour la détection des menaces, le contrôle de conformité et l'audit de sécurité global.

#### **Composants Clés**

* **Wazuh Agent :** Déployé sur les nœuds (EC2 / VM) pour collecter les logs système, vérifier l'intégrité des fichiers (FIM) et scanner les vulnérabilités.
* **Wazuh Server (Manager) :** Reçoit et analyse les données envoyées par les agents via un moteur de règles pour corréler les menaces.
* **Wazuh Indexer :** Un moteur de recherche et d'analyse basé sur OpenSearch / Elasticsearch pour stocker et indexer les événements de sécurité.
* **Wazuh Dashboard :** L'interface graphique permettant de visualiser les tableaux de bord, rechercher des événements et gérer les incidents.

---

### 3. Comment les utiliser ensemble ?

Falco et Wazuh **ne se font pas concurrence**, ils se complètent :

* **Falco** est ultra-rapide et ultra-spécifique aux **comportements internes des conteneurs/K8s** (niveau Kernel).
* **Wazuh** apporte une **vue globale (SIEM)** sur l'ensemble de l'infrastructure (les nœuds EC2, l'audit AWS CloudTrail, la gestion de conformité CIS benchmarks).

#### **Architecture d'intégration recommandée :**

1. **Falco** détecte une anomalie dans un conteneur Kubernetes (ex: modification d'un binaire).
2. **Falco Sidekick** envoie l'événement au **Wazuh Manager** (via Syslog ou HTTP API).
3. **Wazuh** centralise l'alerte de Falco, la corrèle avec les autres logs système du nœud (ex: logs SSH, audit Kubernetes, événements AWS CloudTrail) et déclenche l'alerte finale.

---

### 4. Que faut-il ajouter pour la gestion des alertes ?

Bien que Wazuh dispose d'une interface de visualisation, vous devez associer cette stack à d'autres outils pour la gestion opérationnelle des alertes :

1. **Alerting & Notification Instantanée :**
* **Slack / Microsoft Teams / PagerDuty / Opsgenie :** Falco Sidekick ou Wazuh envoient directement les alertes critiques pour une réaction immédiate des équipes SecOps.


2. **Gestion de Tickets & Incidents :**
* **Jira / ServiceNow / n8n :** Automatisation de la création de tickets dès la détection d'une menace critique.


3. **Réponse Automatique (SOAR) :**
* **Wazuh Active Response :** Peut exécuter automatiquement un script sur le nœud pour bloquer une IP ou isoler un hôte.
* **Kubectl / Argo / n8n :** Vous pouvez déclencher une réponse automatique via webhook (ex: isoler ou tuer immédiatement le Pod suspect détecté par Falco).



---

### 💡 La réponse idéale en entretien (En 30 secondes)

> *"Sur la partie DevSecOps, j'associe **Falco** et **Wazuh** pour couvrir la sécurité en profondeur. **Falco** agit comme un capteur de runtime K8s ultra-rapide au niveau eBPF/Kernel pour détecter immédiatement les comportements suspects dans les pods (comme l'ouverture d'un shell). **Wazuh** sert de SIEM centralisé pour corréler les alertes Falco avec les logs des nœuds, le control plane et AWS CloudTrail. Pour les alertes, j'utilise **Falco Sidekick** et les intégrateurs **Wazuh** pour router les événements critiques vers Slack/PagerDuty ou déclencher des workflows d'isolation automatique."*