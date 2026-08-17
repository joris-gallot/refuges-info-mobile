# Refuges Info Mobile

Application mobile communautaire permettant de consulter les refuges et autres points d'intérêt publiés sur [Refuges.info](https://www.refuges.info/).

> Ce projet est indépendant et non officiel. Il n'est ni développé ni validé par l'association Refuges.info.

Le projet démarre avec une cible iOS, tout en conservant la compatibilité Android. Il ne remplace pas le site public Refuges.info, qui reste la destination pour contribuer et ajouter des commentaires.

## État du projet

Le projet est en cours de création. La première version prévoit notamment :

- une carte des refuges et points d'intérêt ;
- la recherche et les filtres ;
- des fiches détaillées ;
- la lecture des commentaires et photos ;
- les favoris ;
- une consultation hors ligne ;
- des liens vers Refuges.info pour contribuer.

Aucune solution cartographique n'est encore intégrée. Le choix sera fait après comparaison des fonctionnalités, des licences, de l'attribution requise et du support hors ligne. Les serveurs de tuiles OpenStreetMap standards ne seront pas utilisés pour du téléchargement massif.

## Prérequis

- Flutter 3.47.0 ;
- Dart 3.13.0 ;
- Xcode et CocoaPods pour iOS ;
- Android SDK pour Android.

## Démarrage

```sh
flutter pub get
flutter run
```

Pour cibler un simulateur iOS :

```sh
flutter devices
flutter run -d <device-id>
```

## Structure

Le code suit une organisation feature-first minimale :

```text
lib/
├── app/                         # Configuration globale de l'application
├── features/
│   └── home/
│       └── presentation/        # Écran d'accueil
└── main.dart                    # Point d'entrée
```

Les couches de données et de domaine seront ajoutées à chaque fonctionnalité lorsqu'elles deviendront nécessaires. Les modèles seront créés à partir de réponses réelles de l'[API Refuges.info](https://www.refuges.info/api/doc/).

## Vérifications

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Ces vérifications sont également exécutées par GitHub Actions sur chaque pull request et chaque push sur `main`.

## Licences et attribution

Le code source de cette application est distribué sous [licence MIT](LICENSE).

Les données restent la propriété de leurs contributeurs et sont mises à disposition par Refuges.info sous licence [Creative Commons Attribution - Partage dans les Mêmes Conditions 2.0](https://creativecommons.org/licenses/by-sa/2.0/deed.fr) (CC BY-SA 2.0). Toute vue utilisant ces données doit afficher clairement cette attribution.

Les marques, noms et éventuels éléments graphiques de Refuges.info ne sont pas couverts par la licence MIT de ce dépôt. Ce projet ne reprend pas le logo officiel.
