## Exercice 1 : Analyse de Logs

### Format des logs : DATE | IP | URL | STATUS | SIZE

### 1. Logique MapReduce pour extraire les lignes avec erreur 404

**Mapper :**
- Entrée : (offset, ligne)
- Traitement : Chercher "404" dans le champ STATUS
- Sortie : (null, ligne_complète) uniquement si STATUS = 404

**Pas de Reducer nécessaire** (job map-only)

### 2. Rôle du Reducer - Est-il indispensable ?

Dans ce cas précis, le **Reducer n'est pas indispensable** car on veut juste filtrer, pas agréger. On peut utiliser un job avec 0 reducer :

```java
job.setNumReduceTasks(0);
```

3. Compter les requêtes par adresse IP (clé du Mapper)

Pour compter les requêtes par IP, la clé de sortie du Mapper doit être l'adresse IP :

```java
// Sortie Mapper
context.write(ip, new IntWritable(1));
```

Le Reducer fera la somme.

Exercice 2 : Inverted Index

Objectif : mot → [doc_id1, doc_id2, ...]

1. Structure de la paire (Clé, Valeur) produite par le Mapper

```
Clé : le mot (Token)
Valeur : l'identifiant du document (doc_id)
```

Exemple pour le document "docA" contenant "Hadoop MapReduce" :

· ("Hadoop", "docA")
· ("MapReduce", "docA")

2. Traitement par le Reducer pour éviter les doublons

```java
public void reduce(Text key, Iterable<Text> values, Context context) {
    Set<String> uniqueDocs = new HashSet<>();
    for (Text val : values) {
        uniqueDocs.add(val.toString());
    }
    context.write(key, new Text(uniqueDocs.toString()));
}
```

3. Flux de données pour le mot "Hadoop" (présent dans docA et docB)

```
Étape Map (Phase 1) :
docA → ("Hadoop", "docA")
docB → ("Hadoop", "docB")

Étape Shuffle (Phase 2) :
Regroupement par clé : "Hadoop" → ["docA", "docB"]

Étape Reduce (Phase 3) :
"Hadoop" → ["docA", "docB"] → sortie : "Hadoop" : [docA, docB]
```

Exercice 3 : Analyse de Graphes - "Friends in Common"

Structure des données : Utilisateur → Liste_amis

Exemple : A → B, C, D

1. Algorithme MapReduce pour trouver les amis communs

Mapper :

```
Pour chaque utilisateur U avec ses amis [A, B, C] :
    Pour chaque paire d'amis (X, Y) où X < Y :
        Émettre ((X, Y), U)
```

Reducer :

```
Pour chaque paire (X, Y) reçue :
    La liste des valeurs est la liste des amis communs
    Émettre ((X, Y), liste_des_amis_communs)
```

Exemple concret :

· Entrée : A → B, C, D
· Mapper émet : ((B,C), A), ((B,D), A), ((C,D), A)

2. Problème de la célébrité (10 millions d'amis)

Risques :

· Nombre de paires = n × (n-1) / 2 ≈ 5 × 10¹³ (explosion combinatoire)
· Le Mapper produit un nombre gigantesque de paires

Impact sur le Shuffle :

· Transfert réseau massif (des téraoctets de données)
· Mémoire du Reducer saturée
· Risque de "OutOfMemoryError"

Solutions possibles :

· Approche par échantillonnage
· MapReduce itératif (traiter les célébrités séparément)
· Utiliser un Combiner pour réduire localement

Exercice 4 : Optimisation via le Combiner

Contexte : Calcul de la température moyenne par ville sur 10 ans

1. Problème : le Combiner pour une moyenne est complexe

La moyenne n'est pas associative :

```
Moyenne(10, 20) = 15
Moyenne(15, 30) = 22.5
Mais Moyenne(10, 20, 30) = 20
```

Résultat : 15 + 22.5 ≠ 20 × 2

2. Solution alternative

Au lieu d'envoyer une simple moyenne, le Mapper/Combiner doit envoyer un couple (somme, count) :

Mapper :

```
Émettre (ville, (température, 1))
```

Combiner :

```
Agréger localement : (somme_locale, count_local)
Émettre (ville, (somme_locale, count_local))
```

Reducer :

```
somme_totale = somme de toutes les sommes
count_total = somme de tous les counts
moyenne = somme_totale / count_total
```

Avantage : Le Combiner réduit le trafic réseau sans perdre de précision.

Exercice 5 : Jointure Map-Side vs Reduce-Side

Contexte : Joindre Ventes (très lourde) et Produits (très légère)

1. Reduce-Side Join

Fonctionnement :

1. Chaque Mapper lit une table et ajoute un tag ("V_" ou "P_")
2. Le Shuffle groupe par clé de jointure (ex: product_id)
3. Le Reducer fusionne les enregistrements tagués

Pourquoi beaucoup de trafic réseau ?

· Toutes les données (y compris la grosse table Ventes) transitent par le Shuffle
· Les données sont triées et transférées entre nœuds
· Coût réseau proportionnel à la taille des données

2. Map-Side Join avec Distributed Cache

Prérequis : La table Produits tient en mémoire vive

Fonctionnement :

```java
// 1. Ajouter le fichier Produits au cache distribué
job.addCacheFile(new URI("/data/produits.txt"));

// 2. Dans le setup() du Mapper, charger la table en mémoire
public void setup(Context context) {
    Map<String, Product> products = new HashMap<>();
    // Lire le fichier depuis le cache
    // Charger dans une HashMap
}

// 3. Dans map(), faire la jointure directement
public void map(Vente vente, Context context) {
    Product p = products.get(vente.getProductId());
    context.write(vente, p);  // jointure terminée
}
```

Avantages :

· Pas de Shuffle
· Pas de Reducer
· Temps d'exécution très réduit