# Téléchargeur de vidéos pour Claude Code

Colle un lien vidéo dans Claude Code (YouTube, Shorts, LinkedIn, Facebook, Instagram, TikTok, X…) : Claude la télécharge sur ton ordinateur et la prépare pour WhatsApp, ou en qualité maximale, dans le dossier de ton choix. Tout se passe sur ton ordinateur : aucun serveur, aucun compte à créer.

- **WhatsApp** (par défaut) : la meilleure qualité possible sous la limite de 180 Mo de WhatsApp. Si la vidéo est déjà compatible, elle est copiée sans aucune perte. Sinon, l'outil mesure la vidéo et choisit la résolution et le débit, sans jamais gonfler le fichier inutilement.
- **Max** : le meilleur fichier fourni par le site, sans réencodage. Écris « max » avec le lien.
- **Les deux** : écris « les deux ».
- **Discord ou e-mail** : écris « pour Discord » (moins de 10 Mo) ou « par mail » (pièce jointe acceptée par Gmail et Outlook). Même méthode que pour WhatsApp.
- **MP3** : écris « en mp3 » pour garder seulement le son.
- **Extrait** : écris « de 1:20 à 2:05 » (ou seulement un début ou une fin) pour ne garder qu'un passage, avec n'importe quelle version.
- **Résumé ou texte** : écris « résume » pour que Claude te résume la vidéo, ou « donne-moi le texte » pour la transcription complète dans un fichier. Le texte vient des sous-titres de la vidéo.

Astuce : dans WhatsApp, envoie le fichier en **Document** pour éviter que WhatsApp le recompresse.

## Installation (2 minutes)

Une page d'installation à partager est dans `docs/installation.html` (publiée en artefact Claude par l'auteur).

Il faut l'**application Claude** pour ordinateur (Windows ou Mac), avec l'onglet **Code**.

1. Ouvre l'application Claude, va dans l'onglet **Code** et démarre une nouvelle session.
2. Colle ce message et envoie-le :

   > Installe le téléchargeur de vidéos en suivant https://github.com/miguelcorradopicq/claude-video-downloader/blob/main/INSTALLATION.md

3. Claude installe tout seul le plugin, les outils nécessaires (yt-dlp, ffmpeg et deno) et les mises à jour automatiques. Il te pose une seule question : dans quel dossier enregistrer les vidéos, et quelle version faire par défaut. Accepte les autorisations qu'il demande.
4. Ouvre une **nouvelle** session et colle un lien vidéo. C'est tout.

Réglages conseillés pour la session : environnement **This computer** (pas Cloud), aucun dossier, modèle **Sonnet**, effort **Medium**, autorisations **Auto**. N'importe quel modèle sait utiliser l'outil.

Si Claude n'a pas pu activer les mises à jour automatiques (le mode Auto le bloque), tape `/plugin`, onglet **Marketplaces**, **video-tools**, et active **auto-update**.

### Installation manuelle (si tu as la commande `claude` dans un terminal)

```bash
claude plugin marketplace add miguelcorradopicq/claude-video-downloader
```

```bash
claude plugin install video-downloader@video-tools
```

Puis, dans une session : `/video-downloader:installation`.

## Utilisation

| Tu écris | Claude fait |
|---|---|
| un lien | la version par défaut (WhatsApp, sauf si tu as choisi autre chose) |
| un lien + « max » | la version qualité maximale |
| un lien + « les deux » | les deux fichiers |
| un lien + « pour Discord » / « par mail » | une version sous la limite de Discord (9,5 Mo) ou des pièces jointes (13,5 Mo) |
| un lien + « en mp3 » | le son seul |
| un lien + « de 1:20 à 2:05 » | seulement ce passage |
| un lien + « résume » | un résumé, sans télécharger la vidéo |
| un lien + « donne-moi le texte » | la transcription dans un fichier `.txt` |
| plusieurs liens | chaque vidéo, l'une après l'autre |
| une capture d'un post | il cherche le post et télécharge la vidéo |

Commandes (tape `/` dans l'application pour les voir) :

- `/video-downloader:reglages` : changer le dossier, la version par défaut, la limite WhatsApp ou le navigateur à utiliser pour les posts réservés aux membres ;
- `/video-downloader:installation` : réinstaller ou réparer les outils ;
- `/video-downloader:signaler` : signaler un problème ou proposer une amélioration.

### LinkedIn, Instagram, Facebook

Les posts publics passent directement. Pour un post visible seulement une fois connecté, Claude propose d'utiliser la connexion de ton navigateur (Chrome, Edge, Firefox, Safari, Brave). Sous Windows, Chrome et Edge doivent être fermés pendant le téléchargement ; Firefox fonctionne ouvert. Les liens courts `lnkd.in` et les liens de partage sont gérés.

## Mises à jour

L'installation active les mises à jour automatiques : chaque amélioration publiée sur ce dépôt arrive toute seule, au démarrage suivant de l'application (l'application affiche « Plugin updated »).

Pour vérifier ou forcer à la main : tape `/plugin` dans une session, onglet **Marketplaces**, choisis **video-tools** : l'option **auto-update** doit être active, et **Update marketplace** force la mise à jour.

Les changements sont listés dans [CHANGELOG.md](CHANGELOG.md).

## Signaler un problème ou proposer une idée

- Le plus simple : tape `/video-downloader:signaler` et décris le problème ; Claude prépare le ticket, te le montre et l'envoie avec ton accord.
- Ou directement : [nouveau ticket](https://github.com/miguelcorradopicq/claude-video-downloader/issues/new/choose) (compte GitHub gratuit nécessaire).

Les tickets sont publics : n'y mets pas d'information personnelle.

## Réglages

Ils sont enregistrés dans le fichier `.video-downloader.json` de ton dossier personnel :

| Réglage | Rôle | Par défaut |
|---|---|---|
| Dossier | où enregistrer les vidéos | Téléchargements |
| Mode | WhatsApp, Max ou LesDeux | WhatsApp |
| LimiteMo | taille maximale de la version WhatsApp | 178 (limite WhatsApp : 180 Mo) |
| Navigateur | connexion à réutiliser pour les posts réservés aux membres | aucun |

Change-les en le demandant à Claude ou avec `/video-downloader:reglages`.

## Ce qui est installé sur l'ordinateur

- **yt-dlp** : téléchargement depuis les sites vidéo ;
- **ffmpeg** : préparation des fichiers ;
- **deno** : moteur JavaScript dont yt-dlp a besoin pour YouTube ;
- sur Mac seulement, **PowerShell** (`brew install powershell`), qui fait tourner le script.

Sous Windows, ils sont installés avec winget ; sur Mac, avec Homebrew. yt-dlp est mis à jour automatiquement une fois par semaine, pour suivre les changements des sites vidéo.

## Contenu du dépôt

```
.claude-plugin/marketplace.json        catalogue « video-tools »
INSTALLATION.md                        instructions d'installation suivies par Claude
CHANGELOG.md                           historique des versions
plugins/video-downloader/
  .claude-plugin/plugin.json           description du plugin
  skills/video-downloader/SKILL.md     téléchargement (déclenché par un lien)
  skills/video-downloader/scripts/video.ps1   le script qui fait le travail
  skills/installation/SKILL.md         installation et réparation
  skills/reglages/SKILL.md             réglages
  skills/signaler/SKILL.md             signalement de problèmes et d'idées
```

Le script peut aussi être lancé seul, sans Claude : `video.ps1 "<lien>" [-Mode WhatsApp|Max|LesDeux|Audio] [-Pour WhatsApp|Discord|Email] [-Debut 1:20] [-Fin 2:05] [-Texte] [-Dossier "<dossier>"]`, et `video.ps1 -Reglages`, `-Verifier`, `-InstallerOutils`, `-Enregistrer`.

## Pour l'auteur

Règles de modification, fonctionnement détaillé et points connus : [MAINTENANCE.md](MAINTENANCE.md).

Ne télécharge que des vidéos que tu as le droit de télécharger.
