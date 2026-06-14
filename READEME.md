# Hadoop TPs - Solutions Complètes

**Étudiant:** [Votre Nom]
**Classe:** [Votre Classe]

## Contenu

| Fichier | Description |
|---------|-------------|
| TP1_HDFS.md | HDFS - Commandes, blocs, réplication, tolérance aux pannes |
| TP2_MapReduce.md | MapReduce - WordCount, Index inversé, Friends in Common |
| TP3_YARN.md | YARN - ResourceManager, Schedulers, Docker |
| synthese.md | Tableau récapitulatif des concepts |

## Commandes rapides

```bash
# HDFS
hdfs dfs -ls /user/
hdfs dfs -put fichier.txt /user/
hdfs dfs -get /user/fichier.txt .

# MapReduce
hadoop jar mon.jar MainClass input output

# YARN
yarn application -list
yarn logs -applicationId <ID>