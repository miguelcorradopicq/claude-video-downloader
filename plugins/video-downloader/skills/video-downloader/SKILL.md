---
name: video-downloader
description: Télécharge une vidéo à partir d'un lien (YouTube, YouTube Shorts, LinkedIn, Facebook, Instagram, TikTok, X/Twitter, Vimeo et la plupart des sites gérés par yt-dlp) et la prépare pour WhatsApp (meilleure qualité sous la limite de 180 Mo) ou en qualité maximale. À utiliser dès que l'utilisateur colle un lien vidéo, même sans rien d'autre, ou dit « télécharge cette vidéo », « pour WhatsApp », « en max », « les deux », ou envoie une capture d'un post vidéo en demandant de la récupérer.
argument-hint: <lien de la vidéo> [whatsapp | max | les deux]
allowed-tools: PowerShell(powershell *) PowerShell(pwsh *) Bash(powershell *) Bash(pwsh *)
---

# Téléchargeur de vidéos

Tout le travail est fait par le script `${CLAUDE_SKILL_DIR}/scripts/video.ps1` : téléchargement avec yt-dlp, puis copie sans perte ou réencodage H.264 adaptatif pour WhatsApp. Ne jamais refaire les commandes ffmpeg à la main.

Réponds toujours en français.

## Lancer le script

- Windows : `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/scripts/video.ps1" "<LIEN>" [-Mode WhatsApp|Max|LesDeux]`
- macOS / Linux : `pwsh -NoProfile -File "${CLAUDE_SKILL_DIR}/scripts/video.ps1" "<LIEN>" [-Mode ...]`
- Délai de la commande : 10 minutes. Si la vidéo dure plus d'environ 15 minutes et doit être réencodée, lance-la en arrière-plan.
- La dernière ligne donne le résultat : `WHATSAPP : <chemin> (<taille>) <comment>` et/ou `MAX : ...`.

## Quelle version

- **Par défaut : le mode enregistré dans les réglages (normalement WhatsApp). Ne pose pas la question.**
- « max », « qualité max », « original », « pleine qualité » → `-Mode Max`.
- « les deux » → `-Mode LesDeux`.
- Plusieurs liens dans un message → un lancement par lien.
- « mets-la dans <dossier> » pour une seule vidéo → `-Dossier "<dossier>"` (sans changer les réglages).

## Avant le premier téléchargement

Si le script répond « Outils manquants » ou si les réglages n'ont jamais été créés (`-Reglages` affiche « pas encore créés »), suis d'abord le skill `installation` de ce plugin (`/video-downloader:installation`), puis reprends le téléchargement.

Si le script affiche « DENO MANQUANT » (installations faites avant l'ajout de deno), lance-le une fois avec `-InstallerOutils` après le téléchargement, sans poser de question, et dis-le en une ligne.

## Cas particuliers

- Garde le lien tel quel : le script nettoie déjà les paramètres de partage LinkedIn et résout les liens courts `lnkd.in`.
- Capture d'écran sans lien : retrouve le post (recherche web sur l'auteur et le texte), dis quelle source tu as utilisée, puis télécharge-la. Si tu ne la trouves pas, demande le lien (« ··· » puis « Copier le lien »).
- « ECHEC DU TELECHARGEMENT » sur un post réservé aux membres (LinkedIn, Instagram, Facebook) : explique que le site demande d'être connecté et propose d'utiliser la connexion du navigateur. Si l'utilisateur accepte, relance avec `-Navigateur chrome` (ou `edge`, `firefox`, `safari`, `brave`). Sous Windows, Chrome et Edge doivent être fermés pendant le téléchargement ; Firefox fonctionne ouvert. Si ça marche, propose de l'enregistrer par défaut (`-Enregistrer -Navigateur <nom>`).
- yt-dlp trop ancien (« Unable to extract », erreur HTTP 403 sur YouTube) : mets-le à jour (`winget upgrade --id yt-dlp.yt-dlp -e` sous Windows, `brew upgrade yt-dlp` sur Mac), puis réessaie une fois.
- Autre erreur persistante : propose de la signaler avec `/video-downloader:signaler`.

## Réponse à l'utilisateur

Une ou deux phrases courtes : nom du fichier, taille, dossier, et si la vidéo a été copiée sans perte ou réencodée (avec la résolution). À dire une seule fois : dans WhatsApp, envoyer le fichier en **Document** évite que WhatsApp le recompresse.

## Comment est faite la version WhatsApp (si on te le demande)

Limite de 180 Mo, comptée comme Windows l'affiche ; cible 178 Mo. Si la vidéo est déjà en H.264/AAC et sous la limite, elle est copiée sans réencodage. Sinon, le script encode trois extraits de 15 secondes à chaque hauteur (1080, 720, 540, 480, 360) en CRF 22, garde la plus haute qui tient, puis fait un encodage libx264 en deux passes au plus petit du budget et du débit d'un CRF 18 : une vidéo simple n'est jamais gonflée jusqu'à la limite.
