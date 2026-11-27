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
5. Avant d'envoyer : `claude plugin validate .` à la racine. Sur Windows avec l'application de bureau, la commande `claude` n'est pas forcément dans le PATH : prendre le plus récent `claude.exe` dans un dossier `claude-code` sous `%LOCALAPPDATA%\Claude-Data\` (versions récentes de l'application) ou sous `%APPDATA%\Claude\claude-code\` (anciennes versions). La commande PowerShell est dans `INSTALLATION.md`, étape 1.
6. Après l'envoi, pour l'avoir tout de suite chez soi : `claude plugin marketplace update video-tools` puis `claude plugin update video-downloader@video-tools`, et redémarrer l'application.

## Comment l'outil choisit la version WhatsApp

- Limite WhatsApp : 180 Mo, comptée comme Windows l'affiche (Mio). Un fichier de 178,76 Mo est passé lors d'un test ; la cible est donc 178 Mo.
- Vidéo déjà en H.264/AAC sous la limite : copie sans réencodage.
- Sinon : trois extraits de 15 s encodés en CRF 22 à chaque hauteur (1080, 720, 540, 480, 360), on garde la plus haute qui tient ; encodage final libx264 en deux passes au plus petit du budget et du débit d'un CRF 18. Le résultat d'un encodage 2 passes dépasse d'environ 1,3 % le calcul, d'où la marge de 0,985.
- Mesures : au même débit, le 720p bat le 540p (SSIM 0,996 contre 0,983 sur une conférence filmée).
- WhatsApp refuse le VP9 ; un envoi en « Document » évite la recompression de WhatsApp (sources non officielles).
- Mêmes calculs pour `-Pour Discord` (9,5 Mio, sous la limite de 10 Mo de Discord en version gratuite) et `-Pour Email` (13,5 Mio : une pièce jointe grossit d'environ 37 % à l'envoi, ce qui reste sous 20 Mo pour Outlook et 25 Mo pour Gmail). Sous 600 kb/s au total, le son est réencodé en 64 kb/s.

## Autres fonctions du script

- **Audio** (`-Mode Audio`) : télécharge seulement la meilleure piste audio (`-f ba/b`) puis la convertit en MP3 VBR qualité 2 (libmp3lame).
- **Extrait** (`-Debut`, `-Fin`) : la vidéo entière est téléchargée, puis coupée avec ffmpeg (`-ss` avant `-i`, `-t` pour la durée) et réencodée en CRF 18 pour une coupe exacte ; la version demandée est préparée à partir de cet extrait. En mode Audio, la coupe est faite directement dans la conversion MP3. Le nom du fichier reçoit « - extrait 1m20-2m05 ».
- **Texte** (`-Texte`) : yt-dlp récupère seulement les sous-titres (`--write-subs --write-auto-subs`, langues `fr`, `en` et toutes les pistes `-orig`). Priorité : `fr-orig`, puis toute piste `-orig` (langue d'origine des sous-titres automatiques de YouTube), puis `fr`, puis `en`. Les balises et les lignes répétées des sous-titres automatiques sont retirées, et le texte est coupé en lignes d'environ 100 caractères. Pour un résumé, le skill passe un dossier temporaire et supprime le fichier ensuite.
- **Mise à jour de yt-dlp** : à chaque téléchargement depuis un lien, si le fichier `~/.video-downloader-maj` a plus de 7 jours, `winget upgrade --id yt-dlp.yt-dlp` (ou `brew upgrade yt-dlp`) puis la date est mise à jour, même en cas d'échec.

## Points connus

- LinkedIn : les liens courts `lnkd.in` et les paramètres de partage font échouer yt-dlp ; le script les résout et les retire. Les vidéos LinkedIn n'ont pas de nom d'auteur (le nom de fichier commence par « Video - »).
- Posts réservés aux membres : option `-Navigateur` (cookies du navigateur ; sous Windows, Chrome et Edge doivent être fermés).
- YouTube : yt-dlp a besoin d'un moteur JavaScript (deno) pour extraire tous les formats ; sans lui, il affiche « No supported JavaScript runtime could be found » et certains formats peuvent manquer. `-InstallerOutils` installe deno (winget `DenoLand.Deno`, Homebrew `deno`) ; un téléchargement sans deno n'est pas bloqué mais le script affiche « DENO MANQUANT ».
- Emplacement de `claude.exe` sous Windows : vu le 2026-11-25 sous `%LOCALAPPDATA%\Claude-Data\<dossier du compte>\claude-code\<version>\<id>\` (application 2.1.330), et non plus sous `%APPDATA%\Claude\claude-code\`.
- Pas encore vérifiés : l'emplacement exact de `claude` dans l'application Mac (`Claude/claude-code` ou `Claude-Data/.../claude-code`), et si `allowed-tools` évite toutes les demandes d'autorisation à chaque téléchargement. À contrôler lors des premières installations.

## Idées en attente

- Tickets ouverts : https://github.com/miguelcorradopicq/claude-video-downloader/issues
