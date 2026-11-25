---
name: installation
description: Installe et configure le téléchargeur de vidéos sur cet ordinateur : outils yt-dlp et ffmpeg, dossier d'enregistrement, version par défaut, mises à jour automatiques du plugin, puis un téléchargement d'essai. À utiliser juste après l'installation du plugin, quand le script signale des outils manquants, ou quand l'utilisateur dit « installe », « configure », « répare » le téléchargeur de vidéos.
allowed-tools: PowerShell(powershell *) PowerShell(pwsh *) Bash(powershell *) Bash(pwsh *)
---

# Installation du téléchargeur de vidéos

Réponds en français. Fais tout toi-même ; l'utilisateur n'a qu'à répondre à une seule question (étape 3). Annonce en une ligne ce que tu vas installer avant de commencer.

Script : `${CLAUDE_SKILL_DIR}/../video-downloader/scripts/video.ps1`. Sous Windows, lance-le avec `powershell -NoProfile -ExecutionPolicy Bypass -File "<script>" ...` ; sur macOS / Linux, avec `pwsh -NoProfile -File "<script>" ...`.

## 1. PowerShell (macOS / Linux seulement)

Sous Windows, PowerShell est déjà là. Sur Mac, si `pwsh` est introuvable : `brew install powershell` (si `brew` manque aussi, dis à l'utilisateur d'installer Homebrew depuis https://brew.sh, puis reprends).

## 2. Outils yt-dlp et ffmpeg

Lance le script avec `-InstallerOutils`. Il utilise winget (Windows) ou Homebrew (Mac) et installe seulement ce qui manque.
- S'il répond « OUTILS OK », passe à la suite.
- S'il répond « OUTILS MANQUANTS après installation », c'est en général le PATH qui n'est pas encore à jour : dis à l'utilisateur de quitter complètement l'application Claude (aussi depuis la zone de notification sous Windows), de la rouvrir, puis de taper `/video-downloader:installation` pour finir.

## 3. Réglages (une seule question à l'utilisateur)

Lance `-Reglages`. Si les réglages existent déjà, montre-les et demande seulement s'il veut les changer. Sinon, demande en un seul message :
- **le dossier** où enregistrer les vidéos (propose son dossier Téléchargements ; un dossier Google Drive, OneDrive ou Dropbox marche aussi) ;
- **la version par défaut** : WhatsApp (recommandé : meilleure qualité sous 180 Mo) ou Max (fichier d'origine, sans limite).

Puis : `-Enregistrer -Dossier "<dossier>" -Mode <WhatsApp|Max>`.

## 4. Mises à jour automatiques du plugin

Ouvre `~/.claude/settings.json` (Windows : `%USERPROFILE%\.claude\settings.json`). Dans `extraKnownMarketplaces`, l'entrée `video-tools` doit contenir `"autoUpdate": true` à côté de `source` :

```json
"extraKnownMarketplaces": {
  "video-tools": {
    "source": { "source": "github", "repo": "miguelcorradopicq/claude-video-downloader" },
    "autoUpdate": true
  }
}
```

Ajoute ou corrige seulement cette entrée, sans toucher au reste du fichier, et vérifie que le JSON reste valide. Dans `enabledPlugins`, `"video-downloader@video-tools": true` doit être présent.

## 5. Essai

Télécharge cette courte vidéo publique avec le mode par défaut, puis vérifie que le fichier est bien dans le dossier choisi : `https://www.youtube.com/shorts/xIg2FZO7LUg`. Propose ensuite de supprimer le fichier d'essai (seulement si l'utilisateur dit oui).

## 6. Fin

Résume en trois lignes : outils installés, dossier et version par défaut, mises à jour automatiques actives. Rappelle les commandes utiles :
- coller un lien vidéo suffit (ajouter « max » ou « les deux » si besoin) ;
- `/video-downloader:reglages` pour changer le dossier ou la version par défaut ;
- `/video-downloader:signaler` pour signaler un problème ou proposer une amélioration.
