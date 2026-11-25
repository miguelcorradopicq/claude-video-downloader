# Maintenance (pour l'auteur et son Claude)

Ce fichier sert à reprendre le projet dans n'importe quelle session Claude Code : il contient tout ce qu'il faut savoir pour le modifier sans rien casser.

## Le projet

- Dépôt public : `miguelcorradopicq/claude-video-downloader`.
- C'est à la fois un **marketplace** Claude Code (`video-tools`, fichier `.claude-plugin/marketplace.json`) et un **plugin** (`video-downloader`, dossier `plugins/video-downloader`).
- Utilisateurs : l'auteur et ses amis, **uniquement avec l'application Claude Desktop (onglet Code)**, sous Windows ou Mac.
- Installation chez un utilisateur : il colle le message indiqué dans le README ; son Claude suit `INSTALLATION.md`.

## Règles à respecter à chaque modification

1. **Tout en français, rien en anglais** : skills, messages du script, documentation, tickets.
2. Dans le **même envoi** que la modification, mettre à jour : `README.md`, `CHANGELOG.md`, `INSTALLATION.md` si l'installation change, et `docs/installation.html`. Si la page d'installation est publiée en artefact Claude, la republier au même lien.
3. **Ne jamais ajouter de champ `version`** dans `plugin.json` ni dans `marketplace.json` : sans lui, chaque envoi sur GitHub est une nouvelle version et part automatiquement chez tous ceux qui ont activé l'auto-update.
4. Le script `video.ps1` doit rester en **UTF-8 avec BOM** (sinon Windows PowerShell 5.1 abîme les accents) et compatible PowerShell 5.1 et 7, Windows et macOS.
5. Avant d'envoyer : `claude plugin validate .` à la racine. Sur Windows avec l'application de bureau, la commande `claude` n'est pas forcément dans le PATH : prendre le plus récent `claude.exe` sous `%APPDATA%\Claude\claude-code\`.
6. Après l'envoi, pour l'avoir tout de suite chez soi : `claude plugin marketplace update video-tools` puis `claude plugin update video-downloader@video-tools`, et redémarrer l'application.

## Comment l'outil choisit la version WhatsApp

- Limite WhatsApp : 180 Mo, comptée comme Windows l'affiche (Mio). Un fichier de 178,76 Mo est passé lors d'un test ; la cible est donc 178 Mo.
- Vidéo déjà en H.264/AAC sous la limite : copie sans réencodage.
- Sinon : trois extraits de 15 s encodés en CRF 22 à chaque hauteur (1080, 720, 540, 480, 360), on garde la plus haute qui tient ; encodage final libx264 en deux passes au plus petit du budget et du débit d'un CRF 18. Le résultat d'un encodage 2 passes dépasse d'environ 1,3 % le calcul, d'où la marge de 0,985.
- Mesures : au même débit, le 720p bat le 540p (SSIM 0,996 contre 0,983 sur une conférence filmée).
- WhatsApp refuse le VP9 ; un envoi en « Document » évite la recompression de WhatsApp (sources non officielles).

## Points connus

- LinkedIn : les liens courts `lnkd.in` et les paramètres de partage font échouer yt-dlp ; le script les résout et les retire. Les vidéos LinkedIn n'ont pas de nom d'auteur (le nom de fichier commence par « Video - »).
- Posts réservés aux membres : option `-Navigateur` (cookies du navigateur ; sous Windows, Chrome et Edge doivent être fermés).
- Pas encore vérifiés : l'emplacement exact de `claude` dans l'application Mac, et si `allowed-tools` évite toutes les demandes d'autorisation à chaque téléchargement. À contrôler lors des premières installations.

## Idées en attente

- Tickets ouverts : https://github.com/miguelcorradopicq/claude-video-downloader/issues
