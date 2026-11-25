# Historique des versions

Chaque envoi sur GitHub est une nouvelle version : les utilisateurs la reçoivent automatiquement au démarrage suivant de l'application Claude.

## 2026-11-25 (4)

- YouTube : l'installation ajoute **deno**, le moteur JavaScript dont yt-dlp a besoin pour récupérer tous les formats. Si tu avais déjà installé l'outil, Claude l'ajoute tout seul au prochain téléchargement.
- Installation : la commande `claude` de l'application est aussi cherchée sous `%LOCALAPPDATA%\Claude-Data\`, où les versions récentes de l'application la rangent sous Windows.

## 2026-11-25 (3)

- Le dépôt passe sur le compte GitHub `miguelcorradopicq` : tous les liens sont mis à jour. Si tu avais installé l'ancienne version, réinstalle avec le message du README.
- Nouveau fichier `MAINTENANCE.md` : règles et fonctionnement pour reprendre le projet.

## 2026-11-25 (2)

- Tout passe en français : skills, messages du script, documentation.
- Installation entièrement automatique : un seul message à coller dans Claude (voir README), qui installe le plugin, yt-dlp, ffmpeg et active les mises à jour automatiques.
- Nouveaux skills : `installation`, `reglages`, `signaler`.
- Nouveau réglage « Navigateur » pour les posts réservés aux membres (LinkedIn, Instagram, Facebook).
- Le script installe lui-même les outils manquants (`-InstallerOutils`).
- Modèles de tickets en français pour les problèmes et les idées.

## 2026-11-25 (1)

- Première version : téléchargement d'une vidéo à partir d'un lien, version WhatsApp (meilleure qualité sous 180 Mo) ou Max.
