---
name: reglages
description: Affiche ou modifie les réglages du téléchargeur de vidéos : dossier d'enregistrement, version par défaut (WhatsApp, Max ou les deux), limite de taille WhatsApp, navigateur utilisé pour les sites qui demandent d'être connecté. À utiliser quand l'utilisateur dit « change le dossier », « enregistre mes vidéos dans… », « mets la version max par défaut », « mes réglages vidéo », etc.
allowed-tools: PowerShell(powershell *) PowerShell(pwsh *) Bash(powershell *) Bash(pwsh *)
---

# Réglages du téléchargeur de vidéos

Réponds en français.

Script : `${CLAUDE_SKILL_DIR}/../video-downloader/scripts/video.ps1` (Windows : `powershell -NoProfile -ExecutionPolicy Bypass -File "<script>" ...` ; macOS / Linux : `pwsh -NoProfile -File "<script>" ...`).

1. Lance `-Reglages` et montre les valeurs actuelles.
2. Applique ce que l'utilisateur demande avec `-Enregistrer` et seulement les options concernées :
   - `-Dossier "<chemin>"` : dossier d'enregistrement (le script le crée s'il n'existe pas) ;
   - `-Mode WhatsApp`, `-Mode Max` ou `-Mode LesDeux` : version faite quand l'utilisateur ne précise rien ;
   - `-LimiteMo <nombre>` : limite de taille de la version WhatsApp (178 par défaut, pour la limite de 180 Mo de WhatsApp) ;
   - `-Navigateur chrome|edge|firefox|safari|brave` : reprendre la connexion de ce navigateur pour les posts réservés aux membres ; `-SansNavigateur` pour l'enlever.
3. Montre les nouvelles valeurs en une ou deux lignes.

Les réglages sont dans `~/.video-downloader.json` ; ne modifie pas ce fichier à la main, passe par le script.
