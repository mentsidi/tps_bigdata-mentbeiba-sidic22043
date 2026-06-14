markdown
# TP3 : YARN - Gestion des Ressources

## Exercice 1 : Exploration de l'interface ResourceManager

### 1. Accès à l'interface Web

URL : `http://localhost:8088`

### 2. Identification des ressources

- **Nœuds actifs** : Onglet "Nodes" → nombre de nœuds avec état "RUNNING"
- **Mémoire totale** : Somme de `yarn.nodemanager.resource.memory-mb` sur tous les nœuds

### 3. Lancement d'un job exemple

```bash
hadoop jar /opt/hadoop-3.2.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar pi 10 100
```

Dans l'interface Web : L'ApplicationMaster apparaît dans la liste des applications en cours.

Exercice 2 : Commandes CLI YARN

1. Lister les applications en cours

```bash
yarn application -list
```

2. Forcer l'arrêt (kill) d'une application

```bash
yarn application -kill application_1234567890123_0001
```

3. Afficher les logs d'un job terminé

```bash
yarn logs -applicationId application_1234567890123_0001
```

Pourquoi l'agrégation de logs est cruciale ?

Sans agrégation (yarn.log-aggregation-enable=true), les logs sont supprimés avec le conteneur après l'exécution. L'agrégation les conserve sur HDFS pour consultation ultérieure.

Exercice 3 : Configuration des Containers

Fichier : yarn-site.xml

1. Propriétés pour mémoire minimale et maximale

```xml
<!-- Mémoire minimale d'un container (en Mo) -->
<property>
    <name>yarn.scheduler.minimum-allocation-mb</name>
    <value>1024</value>
</property>

<!-- Mémoire maximale d'un container (en Mo) -->
<property>
    <name>yarn.scheduler.maximum-allocation-mb</name>
    <value>8192</value>
</property>
```

2. Que se passe-t-il si un utilisateur demande 4 Go mais que maximum-allocation est 2 Go ?

Le job échoue immédiatement avec l'erreur :

```
InvalidResourceRequestException: Invalid resource request!
Requested memory < 4GB > exceeds maximum allowed < 2GB >
```

Exercice 4 : Les Schedulers (FIFO vs Capacity)

1. Fonctionnement du Capacity Scheduler

Principe :

· Découpage du cluster en files d'attente (queues) hiérarchiques
· Chaque file a une capacité garantie (ex: Finance 40%, Marketing 60%)
· Partage élastique : une file peut utiliser les ressources libres des autres

Garantie des ressources au département "Finance" :

```xml
<property>
    <name>yarn.scheduler.capacity.root.finance.capacity</name>
    <value>40</value>  <!-- 40% garantis -->
</property>
<property>
    <name>yarn.scheduler.capacity.root.finance.maximum-capacity</name>
    <value>80</value>  <!-- Peut monter à 80% si libre -->
</property>
```

2. Définition de la Preemption

Preemption (Préemption) : Mécanisme qui permet au scheduler de récupérer des ressources allouées à une file de faible priorité pour les donner à une file prioritaire qui n'a pas ses ressources garanties.

Exemple : Si Finance a droit à 40% mais n'en a que 30% car Marketing utilise 70%, le scheduler peut "tuer" des containers de Marketing pour les redonner à Finance.

Docker-Compose pour YARN

Fichier : docker-compose.yml

```yaml
version: "3"
services:
  resourcemanager:
    image: bde2020/hadoop-resourcemanager:2.0.0-hadoop3.2.1-java8
    container_name: resourcemanager
    ports:
      - "8088:8088"
    networks:
      - hadoop_yarn

  nodemanager:
    image: bde2020/hadoop-nodemanager:2.0.0-hadoop3.2.1-java8
    container_name: nodemanager
    environment:
      - YARN_CONF_yarn_nodemanager_resource_memory-mb=4096
      - YARN_CONF_yarn_scheduler_maximum-allocation-mb=2048
    depends_on:
      - resourcemanager
    networks:
      - hadoop_yarn

networks:
  hadoop_yarn:
```

Exercice d'application Docker

1. Observation des limites

```bash
docker-compose up -d
# Accéder à http://localhost:8088
# Vérifier la capacité totale : 4096 Mo
```

2. Saturation des ressources

Lancer deux jobs gourmands simultanément :

```bash
# Terminal 1
hadoop jar /opt/hadoop-3.2.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar pi 50 1000

# Terminal 2 (immédiatement après)
hadoop jar /opt/hadoop-3.2.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar pi 50 1000
```

Observation : Le second job reste en état "ACCEPTED" ou "PENDING" jusqu'à ce que des containers se libèrent.

3. Modification dynamique

Changer la mémoire dans docker-compose.yml :

```yaml
- YARN_CONF_yarn_nodemanager_resource_memory-mb=2048  # Au lieu de 4096
```

```bash
docker-compose down
docker-compose up -d
```

Impact : La capacité totale du cluster est immédiatement réduite à 2048 Mo dans l'interface Web.