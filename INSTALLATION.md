# Installation automatique (instructions pour Claude)

> Ce fichier s'adresse à **Claude Code**. L'utilisateur colle simplement ce message dans une nouvelle session de l'onglet Code de l'application Claude :
>
> **Installe le téléchargeur de vidéos en suivant https://github.com/miguelcorradopicq/claude-video-downloader/blob/main/INSTALLATION.md**

Claude : l'utilisateur t'a demandé d'installer ce plugin. Réponds en français, fais tout toi-même et ne lui pose qu'une seule question (les réglages, étape 4). Annonce d'abord en deux lignes ce que tu vas faire : installer le plugin depuis GitHub, installer les outils yt-dlp et ffmpeg, puis lui demander où enregistrer les vidéos.

## 1. Trouver la commande `claude`

L'application de bureau n'ajoute pas toujours `claude` au PATH. Dans l'ordre :
1. `claude --version` : si ça répond, utilise `claude`.
2. Windows : le plus récent des fichiers `claude.exe` sous `%APPDATA%\Claude\claude-code\` (par exemple `%APPDATA%\Claude\claude-code\<version>\<id>\claude.exe`).
3. macOS : le plus récent des fichiers `claude` sous `~/Library/Application Support/Claude/claude-code/`.

Si tu ne trouves aucune commande `claude`, passe directement à l'étape 2 bis.

## 2. Installer le plugin

```
<claude> plugin marketplace add miguelcorradopicq/claude-video-downloader
<claude> plugin install video-downloader@video-tools
```

Si le marketplace existe déjà, lance plutôt `<claude> plugin marketplace update video-tools` puis `<claude> plugin update video-downloader@video-tools`.

### 2 bis. Sans commande `claude`

Ajoute ces deux entrées dans `~/.claude/settings.json` (Windows : `%USERPROFILE%\.claude\settings.json`), en gardant le reste du fichier intact et le JSON valide :

```json
"extraKnownMarketplaces": {
  "video-tools": {
    "source": { "source": "github", "repo": "miguelcorradopicq/claude-video-downloader" },
    "autoUpdate": true
  }
},
"enabledPlugins": {
  "video-downloader@video-tools": true
}
```

Puis dis à l'utilisateur de quitter complètement l'application Claude, de la rouvrir et de taper `/video-downloader:installation` dans une nouvelle session. Arrête-toi là.

## 3. Mises à jour automatiques

Dans `~/.claude/settings.json`, l'entrée `extraKnownMarketplaces.video-tools` doit contenir `"autoUpdate": true` à côté de `source` (voir l'exemple ci-dessus). Ajoute-le s'il manque, sans toucher au reste.

## 4. Outils, réglages et essai

Le plugin est maintenant dans `~/.claude/plugins/marketplaces/video-tools/plugins/video-downloader/`. Suis les étapes 1 à 6 de son fichier `skills/installation/SKILL.md`, en remplaçant `${CLAUDE_SKILL_DIR}/..` par `~/.claude/plugins/marketplaces/video-tools/plugins/video-downloader/skills`. Le script est donc :
- Windows : `%USERPROFILE%\.claude\plugins\marketplaces\video-tools\plugins\video-downloader\skills\video-downloader\scripts\video.ps1`
- macOS : `~/.claude/plugins/marketplaces/video-tools/plugins/video-downloader/skills/video-downloader/scripts/video.ps1`

## 5. Fin

Dis à l'utilisateur que c'est prêt : dans une **nouvelle** session, il lui suffit de coller un lien vidéo. Rappelle-lui `/video-downloader:reglages` et `/video-downloader:signaler`.
