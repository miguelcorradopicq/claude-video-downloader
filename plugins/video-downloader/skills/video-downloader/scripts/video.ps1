<#
.SYNOPSIS
  Télécharge une vidéo (yt-dlp) et la prépare : version légère (WhatsApp, Discord, e-mail), version Max,
  son seul en MP3, extrait, ou texte des sous-titres.

.DESCRIPTION
  Compatible Windows PowerShell 5.1 et PowerShell 7 (Windows, macOS, Linux). Nécessite yt-dlp, ffmpeg et ffprobe
  (et deno, moteur JavaScript dont yt-dlp a besoin pour YouTube).

  Version légère (Mode WhatsApp, avec -Pour WhatsApp|Discord|Email) : la meilleure qualité possible sous la limite,
  sans jamais gonfler le fichier.
    1. Déjà en H.264/AAC et sous la limite -> simple copie (remux), aucune perte.
    2. Sinon, le script MESURE la vidéo : trois extraits de 15 s encodés en CRF 22 à chaque hauteur
       (1080, 720, 540, 480, 360 sur le petit côté) ; il garde la plus haute qui tient.
    3. Encodage final en 2 passes au plus petit de (budget, débit d'un CRF 18).
    Limites : WhatsApp 178 Mo (réglage LimiteMo), Discord 9,5 Mo, e-mail 13,5 Mo (Gmail 25 Mo et Outlook 20 Mo,
    encodage de la pièce jointe compris). -LimiteMo force une autre limite.
  Version Max : le meilleur fichier fourni par le site, sans réencodage.
  LesDeux : la version Max et la version légère, suffixées « - Max » et « - WhatsApp » (ou Discord, Email).
  Audio : le son seul, en MP3 (VBR qualité 2, environ 190 kb/s).
  Extrait : -Debut 1:20 -Fin 2:05 (l'un ou l'autre suffit) coupe avant de préparer la version demandée.
  Texte : -Texte enregistre le texte des sous-titres (langue d'origine, sinon français, sinon anglais) dans un .txt.

  yt-dlp est mis à jour automatiquement une fois par semaine (winget ou Homebrew), au premier téléchargement.

  Réglages (dossier, version par défaut, limite WhatsApp, navigateur) : ~/.video-downloader.json,
  créés ou modifiés avec -Enregistrer.

.EXAMPLE
  ./video.ps1 "https://youtu.be/xxxx"
  ./video.ps1 "https://youtu.be/xxxx" -Mode Max
  ./video.ps1 "https://youtu.be/xxxx" -Mode Audio
  ./video.ps1 "https://youtu.be/xxxx" -Debut 1:20 -Fin 2:05
  ./video.ps1 "https://youtu.be/xxxx" -Pour Discord
  ./video.ps1 "https://youtu.be/xxxx" -Texte
  ./video.ps1 -Enregistrer -Dossier "D:\Vidéos" -Mode WhatsApp
  ./video.ps1 -Reglages
  ./video.ps1 -Verifier
  ./video.ps1 -InstallerOutils
#>
param(
  [Parameter(Position = 0)][string]$Source,
  [ValidateSet('WhatsApp', 'Max', 'LesDeux', 'Audio')][string]$Mode,
  [ValidateSet('WhatsApp', 'Discord', 'Email')][string]$Pour = 'WhatsApp', # destination de la version légère
  [string]$Debut,          # début de l'extrait : 80, 1:20 ou 1:02:03
  [string]$Fin,            # fin de l'extrait
  [switch]$Texte,          # récupérer le texte des sous-titres au lieu de la vidéo
  [string]$Dossier,
  [double]$LimiteMo = 0,
  [string]$Navigateur,     # navigateur dont on reprend la connexion : chrome, edge, firefox, safari, brave
  [switch]$SansNavigateur, # avec -Enregistrer : ne plus utiliser de navigateur par défaut
  [int]$CrfPlancher = 22,  # qualité minimale acceptée pour choisir la résolution
  [int]$CrfPlafond = 18,   # qualité « transparente » : au-delà, inutile de dépenser des octets
  [switch]$Enregistrer,
  [switch]$Reglages,
  [switch]$Verifier,
  [switch]$InstallerOutils
)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
$surWindows = ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows
$surMac = (-not $surWindows) -and $IsMacOS
$nulDev = if ($surWindows) { 'NUL' } else { '/dev/null' }
$maison = [Environment]::GetFolderPath('UserProfile')
$cheminReglages = Join-Path $maison '.video-downloader.json'
$invariant = [Globalization.CultureInfo]::InvariantCulture

# --- Réglages ---------------------------------------------------------------
$cfg = [pscustomobject]@{ Dossier = (Join-Path $maison 'Downloads'); Mode = 'WhatsApp'; LimiteMo = 178; Navigateur = '' }
$existe = Test-Path -LiteralPath $cheminReglages
if ($existe) {
  $lu = Get-Content -LiteralPath $cheminReglages -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($lu.OutDir) { $cfg.Dossier = $lu.OutDir }        # ancien format
  if ($lu.TargetMiB) { $cfg.LimiteMo = $lu.TargetMiB }  # ancien format
  foreach ($k in 'Dossier', 'Mode', 'LimiteMo', 'Navigateur') { if ($null -ne $lu.$k -and "$($lu.$k)" -ne '') { $cfg.$k = $lu.$k } }
  if ($cfg.Mode -eq 'Both') { $cfg.Mode = 'LesDeux' }
}
function Show-Reglages {
  Write-Host ("REGLAGES : {0} ({1})" -f $cheminReglages, $(if (Test-Path -LiteralPath $cheminReglages) { 'enregistrés' } else { 'pas encore créés, valeurs par défaut' }))
  Write-Host ("  Dossier    : {0}" -f $cfg.Dossier)
  Write-Host ("  Mode       : {0}" -f $cfg.Mode)
  Write-Host ("  LimiteMo   : {0}" -f $cfg.LimiteMo)
  Write-Host ("  Navigateur : {0}" -f $(if ($cfg.Navigateur) { $cfg.Navigateur } else { '(aucun)' }))
}
if ($Enregistrer) {
  if ($Dossier) { $cfg.Dossier = $Dossier }
  if ($Mode) { $cfg.Mode = $Mode }
  if ($LimiteMo -gt 0) { $cfg.LimiteMo = $LimiteMo }
  if ($Navigateur) { $cfg.Navigateur = $Navigateur }
  if ($SansNavigateur) { $cfg.Navigateur = '' }
  New-Item -ItemType Directory -Force -Path $cfg.Dossier | Out-Null
  [IO.File]::WriteAllText($cheminReglages, ($cfg | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))
  Write-Host 'REGLAGES enregistrés.'
  Show-Reglages
  if (-not $Source) { return }
}
if ($Reglages) { Show-Reglages; return }

# --- Outils -----------------------------------------------------------------
function Update-Path {
  if ($surWindows) {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
  } elseif (Test-Path '/opt/homebrew/bin') { $env:PATH = "/opt/homebrew/bin:/usr/local/bin:$env:PATH" }
}
# deno : moteur JavaScript dont yt-dlp a besoin pour YouTube (sans lui, certains formats manquent ou échouent).
# Il est installé avec les autres outils, mais son absence ne bloque pas un téléchargement.
function Get-Manquants([switch]$AvecDeno) {
  $outils = @('yt-dlp', 'ffmpeg', 'ffprobe'); if ($AvecDeno) { $outils += 'deno' }
  $outils | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
}
# yt-dlp doit suivre les changements des sites : mise à jour au plus une fois par semaine.
function Update-YtDlp {
  $marque = Join-Path $maison '.video-downloader-maj'
  if ((Test-Path -LiteralPath $marque) -and ((Get-Date) - (Get-Item -LiteralPath $marque).LastWriteTime).TotalDays -lt 7) { return }
  [IO.File]::WriteAllText($marque, (Get-Date -Format s))
  try {
    if ($surWindows -and (Get-Command winget -ErrorAction SilentlyContinue)) {
      winget upgrade --id yt-dlp.yt-dlp -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
    } elseif ($surMac -and (Get-Command brew -ErrorAction SilentlyContinue)) { brew upgrade yt-dlp | Out-Null }
    Write-Host "MISE A JOUR : yt-dlp vérifié (version $(& yt-dlp --version))"
  } catch { Write-Host "MISE A JOUR : yt-dlp n'a pas pu être vérifié, on continue." }
}
Update-Path
if ($InstallerOutils) {
  $m = Get-Manquants -AvecDeno
  if (-not $m) { Write-Host 'OUTILS OK : yt-dlp, ffmpeg, ffprobe et deno sont déjà installés.' }
  elseif ($surWindows) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget est introuvable. Installe « App Installer » depuis le Microsoft Store, puis relance." }
    if ($m -contains 'yt-dlp') { winget install --id yt-dlp.yt-dlp -e --silent --accept-source-agreements --accept-package-agreements | Out-Host }
    if ($m -contains 'ffmpeg' -or $m -contains 'ffprobe') { winget install --id Gyan.FFmpeg -e --silent --accept-source-agreements --accept-package-agreements | Out-Host }
    if ($m -contains 'deno') { winget install --id DenoLand.Deno -e --silent --accept-source-agreements --accept-package-agreements | Out-Host }
  } elseif ($surMac) {
    if (-not (Get-Command brew -ErrorAction SilentlyContinue)) { throw "Homebrew est introuvable. Installe-le depuis https://brew.sh, puis relance." }
    brew install yt-dlp ffmpeg deno | Out-Host
  } else { throw "Installe yt-dlp, ffmpeg et deno avec le gestionnaire de paquets de ta distribution." }
  Update-Path
  $m = Get-Manquants -AvecDeno
  if ($m) { Write-Host "OUTILS MANQUANTS après installation : $($m -join ', '). Ferme et rouvre l'application Claude, puis relance -Verifier." }
  else { Write-Host 'OUTILS OK : yt-dlp, ffmpeg, ffprobe et deno sont installés.' }
  return
}
if ($Verifier) {
  $m = Get-Manquants -AvecDeno
  if ($m) { Write-Host "OUTILS MANQUANTS : $($m -join ', ')" } else { Write-Host 'OUTILS OK : yt-dlp, ffmpeg, ffprobe, deno' }
  Show-Reglages
  return
}
$manquants = Get-Manquants
if ($manquants) { throw "Outils manquants : $($manquants -join ', '). Lance d'abord le script avec -InstallerOutils." }
if (-not (Get-Command deno -ErrorAction SilentlyContinue)) { Write-Host "DENO MANQUANT : yt-dlp en a besoin pour YouTube. Lance le script avec -InstallerOutils pour l'ajouter." }
if (-not $Source) { throw 'Donne un lien ou un fichier vidéo.' }

# --- Paramètres du téléchargement -------------------------------------------
if ($PSBoundParameters.ContainsKey('Pour') -and -not $Mode) { $Mode = 'WhatsApp' }   # « pour Discord » = version légère
if (-not $Dossier) { $Dossier = $cfg.Dossier }
if (-not $Mode) { $Mode = $cfg.Mode }
if ($LimiteMo -le 0) { $LimiteMo = @{ WhatsApp = [double]$cfg.LimiteMo; Discord = 9.5; Email = 13.5 }[$Pour] }
if (-not $Navigateur -and -not $SansNavigateur) { $Navigateur = $cfg.Navigateur }

function ConvertTo-Secondes([string]$t) {
  if ($t -notmatch '^\d+(:\d{1,2}){0,2}([.,]\d+)?$') { throw "Temps invalide : « $t ». Exemples : 80, 1:20, 1:02:03." }
  $s = 0.0
  foreach ($p in $t.Replace(',', '.').Split(':')) { $s = $s * 60 + [double]::Parse($p, $invariant) }
  $s
}
function Format-Temps([double]$s) {
  $ts = [TimeSpan]::FromSeconds([math]::Floor($s))
  if ($ts.Hours -gt 0) { '{0}h{1:00}m{2:00}' -f $ts.Hours, $ts.Minutes, $ts.Seconds } else { '{0}m{1:00}' -f $ts.Minutes, $ts.Seconds }
}
$extrait = [bool]($Debut -or $Fin)
$coupeIn = @(); $coupeOut = @()
if ($extrait) {
  $sDebut = if ($Debut) { ConvertTo-Secondes $Debut } else { 0 }
  $sFin = if ($Fin) { ConvertTo-Secondes $Fin } else { $null }
  if ($null -ne $sFin -and $sFin -le $sDebut) { throw "La fin de l'extrait ($Fin) doit être après le début ($Debut)." }
  if ($sDebut -gt 0) { $coupeIn = @('-ss', $sDebut.ToString($invariant)) }
  if ($null -ne $sFin) { $coupeOut = @('-t', ($sFin - $sDebut).ToString($invariant)) }
  $etiquette = 'extrait {0}-{1}' -f (Format-Temps $sDebut), $(if ($null -ne $sFin) { Format-Temps $sFin } else { 'fin' })
}

$ffmpeg = (Get-Command ffmpeg).Source
$ffprobe = (Get-Command ffprobe).Source
$travail = Join-Path ([IO.Path]::GetTempPath()) ('video-downloader-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $travail, $Dossier | Out-Null
$suffixe = $Mode -eq 'LesDeux'

try {
  # --- 1. Source ------------------------------------------------------------
  $telecharge = $false
  if ($Source -match '^https?://') {
    Update-YtDlp
    $url = $Source
    # Liens courts LinkedIn et paramètres de partage : on résout et on nettoie
    if ($url -match '^https?://lnkd\.in/') {
      try {
        $h = New-Object System.Net.Http.HttpClient
        $r = $h.GetAsync($url).GetAwaiter().GetResult()
        $url = $r.RequestMessage.RequestUri.AbsoluteUri
        $h.Dispose()
      } catch { }
    }
    if ($url -match 'linkedin\.com/') { $url = ($url -split '\?')[0] }
    $format = if ($Mode -eq 'Audio') { 'ba/b' } else { 'bv*[vcodec^=avc1]+ba[ext=m4a]/bv*+ba/b' }
    $ytArgs = @('--ignore-config', '--no-progress', '--no-playlist',
      '-o', '%(uploader,channel,creator|Video)s - %(title).80B [%(id).40B].%(ext)s',
      '--windows-filenames', '-P', $travail)
    if ($Texte) {
      # Sous-titres seulement : langue d'origine (pistes « -orig » de YouTube), sinon français, sinon anglais
      $ytArgs += @('--skip-download', '--write-subs', '--write-auto-subs', '--sub-format', 'vtt/srt/best',
        '--sub-langs', 'fr,fr-FR,fr-orig,en,en-US,en-GB,.*-orig')
    } else { $ytArgs += @('-f', $format, '--merge-output-format', 'mp4') }
    if ($Navigateur) { $ytArgs += @('--cookies-from-browser', $Navigateur) }
    $ytArgs += $url
    & yt-dlp @ytArgs | Out-Host

    # --- Texte des sous-titres ----------------------------------------------
    if ($Texte) {
      $subs = @(Get-ChildItem -LiteralPath $travail -File | Where-Object { $_.Extension -in '.vtt', '.srt' })
      if (-not $subs) { Write-Host "PAS DE SOUS-TITRES : cette vidéo n'a ni sous-titres ni sous-titres automatiques ; impossible d'en tirer le texte."; return }
      $choix = $null
      foreach ($motif in '\.fr-orig\.', '-orig\.', '\.fr(-FR)?\.', '\.en(-\w+)?\.') {
        $choix = $subs | Where-Object { $_.Name -match $motif } | Select-Object -First 1
        if ($choix) { break }
      }
      if (-not $choix) { $choix = $subs[0] }
      $sansExt = [IO.Path]::GetFileNameWithoutExtension($choix.Name)   # « titre [id].fr-orig »
      $langue = [IO.Path]::GetExtension($sansExt).TrimStart('.')
      $baseTexte = [IO.Path]::GetFileNameWithoutExtension($sansExt)
      $lignes = New-Object System.Collections.Generic.List[string]
      foreach ($l in (Get-Content -LiteralPath $choix.FullName -Encoding UTF8)) {
        $l = $l.Trim()
        if (-not $l -or $l -eq 'WEBVTT' -or $l -match '-->' -or $l -match '^\d+$' -or $l -match '^(Kind|Language|NOTE|STYLE)\b') { continue }
        $l = (($l -replace '<[^>]+>', '') -replace '&nbsp;', ' ' -replace '&amp;', '&' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&#39;', "'" -replace '&quot;', '"').Trim()
        # Les sous-titres automatiques répètent la ligne précédente à chaque bloc : on ne la garde qu'une fois
        if ($l -and ($lignes.Count -eq 0 -or $lignes[$lignes.Count - 1] -ne $l)) { $lignes.Add($l) }
      }
      # Lignes d'environ 100 caractères, plus faciles à lire qu'un seul bloc
      $mots = ($lignes -join ' ') -split '\s+' | Where-Object { $_ }
      $sortieTexte = New-Object System.Text.StringBuilder
      [void]$sortieTexte.AppendLine("Source : $Source").AppendLine("Langue des sous-titres : $langue").AppendLine()
      $ligne = ''
      foreach ($mot in $mots) {
        if ($ligne.Length + $mot.Length + 1 -gt 100) { [void]$sortieTexte.AppendLine($ligne); $ligne = $mot } else { $ligne = if ($ligne) { "$ligne $mot" } else { $mot } }
      }
      if ($ligne) { [void]$sortieTexte.AppendLine($ligne) }
      $fichierTexte = Join-Path $Dossier "$baseTexte.txt"
      [IO.File]::WriteAllText($fichierTexte, $sortieTexte.ToString(), (New-Object Text.UTF8Encoding $true))
      Write-Host ("TEXTE    : {0}  ({1} mots, langue {2})" -f $fichierTexte, @($mots).Count, $langue)
      return
    }

    $src = Get-ChildItem -LiteralPath $travail -File |
      Where-Object { $_.Extension -notin '.part', '.ytdl', '.json', '.jpg', '.webp', '.png', '.vtt', '.srt' } |
      Sort-Object Length -Descending | Select-Object -First 1 -ExpandProperty FullName
    if (-not $src) { throw "ECHEC DU TELECHARGEMENT : aucune vidéo récupérée. Si le site demande d'être connecté, relance avec -Navigateur chrome (ou edge, firefox, safari)." }
    $telecharge = $true
  } else {
    if ($Texte) { throw 'Le texte ne peut être récupéré que depuis un lien.' }
    $src = (Resolve-Path -LiteralPath $Source).Path
  }
  $base = [IO.Path]::GetFileNameWithoutExtension($src)
  $ext = [IO.Path]::GetExtension($src)

  # --- 2. Extrait -----------------------------------------------------------
  if ($extrait) {
    $base = "$base - $etiquette"
    if ($Mode -ne 'Audio') {
      # Découpe précise à l'image près : réencodage en qualité quasi transparente (CRF 18)
      $coupe = Join-Path $travail 'extrait.mp4'
      & $ffmpeg -y -hide_banner -loglevel error @coupeIn -i $src @coupeOut -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart $coupe
      if (-not (Test-Path -LiteralPath $coupe)) { throw "ECHEC DE LA DECOUPE : vérifie que le début et la fin sont dans la durée de la vidéo." }
      $src = $coupe; $ext = '.mp4'; $coupeIn = @(); $coupeOut = @()
    }
  }

  function Get-Info($f) {
    $j = & $ffprobe -v error -show_entries 'format=duration,size:stream=codec_type,codec_name,width,height,bit_rate' -of json $f | Out-String | ConvertFrom-Json
    $v = $j.streams | Where-Object { $_.codec_type -eq 'video' } | Select-Object -First 1
    $a = $j.streams | Where-Object { $_.codec_type -eq 'audio' } | Select-Object -First 1
    [pscustomobject]@{
      Dur = [double]$j.format.duration; Size = [double]$j.format.size
      W = [int]$v.width; H = [int]$v.height; V = $v.codec_name
      A = $(if ($a) { $a.codec_name } else { $null }); ABps = $(if ($a -and $a.bit_rate) { [double]$a.bit_rate } else { 0 })
    }
  }
  function Get-Filtre($h) { "scale='if(gt(iw,ih),-2,$h)':'if(gt(iw,ih),$h,-2)'" }

  # --- 3. Audio seul (MP3) --------------------------------------------------
  if ($Mode -eq 'Audio') {
    $sortie = Join-Path $Dossier "$base.mp3"
    $tmp = Join-Path $travail 'sortie.mp3'
    & $ffmpeg -y -hide_banner -loglevel error @coupeIn -i $src @coupeOut -vn -c:a libmp3lame -q:a 2 $tmp
    if (-not (Test-Path -LiteralPath $tmp)) { throw "ECHEC DE L'EXTRACTION DU SON : cette vidéo n'a peut-être pas de piste audio." }
    Move-Item -LiteralPath $tmp -Destination $sortie -Force
    Write-Host ("AUDIO    : {0}  ({1:N1} Mo)  MP3" -f $sortie, ((Get-Item -LiteralPath $sortie).Length / 1MB))
    return
  }

  # --- 4. Version Max -------------------------------------------------------
  if ($Mode -in 'Max', 'LesDeux') {
    if ($telecharge -or $extrait) {
      $nom = if ($suffixe) { "$base - Max$ext" } else { "$base$ext" }
      $dest = Join-Path $Dossier $nom
      if ($suffixe) { Copy-Item -LiteralPath $src -Destination $dest -Force }
      else { Move-Item -LiteralPath $src -Destination $dest -Force; $src = $dest }
      Write-Host ("MAX      : {0}  ({1:N1} Mo){2}" -f $dest, ((Get-Item -LiteralPath $dest).Length / 1MB), $(if ($extrait) { '  extrait réencodé en CRF 18 (qualité quasi identique)' } else { '' }))
    } else { Write-Host 'MAX      : fichier local conservé tel quel.' }
  }

  # --- 5. Version légère (WhatsApp, Discord, e-mail) -------------------------
  if ($Mode -in 'WhatsApp', 'LesDeux') {
    $info = Get-Info $src
    $budget = $LimiteMo * 1MB * 0.985          # marge : l'encodage 2 passes dépasse d'environ 1,3 %
    $nomSortie = if ($suffixe) { "$base - $Pour.mp4" } else { "$base.mp4" }
    $sortie = Join-Path $Dossier $nomSortie
    $tmp = Join-Path $travail 'sortie.mp4'
    $serre = ($budget * 8 / $info.Dur) -lt 600000  # moins de 600 kb/s au total : on économise sur le son

    if ($info.V -eq 'h264' -and ($info.A -eq 'aac' -or -not $info.A) -and $info.Size -le $budget) {
      & $ffmpeg -y -hide_banner -loglevel error -i $src -c copy -movflags +faststart $tmp
      $comment = 'copiée sans réencodage (déjà compatible, aucune perte)'
    } else {
      if ($info.A -eq 'aac' -and $info.ABps -gt 0 -and $info.ABps -le 132000 -and -not $serre) { $aArgs = @('-c:a', 'copy'); $abps = $info.ABps }
      elseif ($info.A) { $ab = if ($serre) { 64 } elseif ($info.Dur -gt 1200) { 96 } else { 128 }; $aArgs = @('-c:a', 'aac', '-b:a', "${ab}k", '-ac', '2', '-ar', '44100'); $abps = $ab * 1000 }
      else { $aArgs = @('-an'); $abps = 0 }

      $vb = ($budget * 8 / $info.Dur) - $abps   # débit vidéo disponible (bit/s)
      $petit = [math]::Min($info.W, $info.H)
      $echelle = @(1080, 720, 540, 480, 360) | Where-Object { $_ -le $petit }
      if (-not $echelle) { $echelle = @($petit) }

      function Get-DebitEchantillon($h, $crf) {
        $entier = $info.Dur -le 45
        $duree = if ($entier) { $info.Dur } else { 15 }
        $debuts = if ($entier) { @(0) } else { @(0.15, 0.5, 0.85) | ForEach-Object { [math]::Floor($_ * ($info.Dur - $duree)) } }
        $octets = 0; $secs = 0
        foreach ($s in $debuts) {
          $p = Join-Path $travail 'sonde.mp4'
          & $ffmpeg -y -hide_banner -loglevel error -ss $s -t $duree -i $src -an -vf (Get-Filtre $h) -c:v libx264 -preset veryfast -crf $crf -pix_fmt yuv420p $p
          $octets += (Get-Item -LiteralPath $p).Length; $secs += $duree
        }
        $octets * 8 / $secs
      }

      $h = $null
      foreach ($cand in $echelle) { if ((Get-DebitEchantillon $cand $CrfPlancher) -le $vb) { $h = $cand; break } }
      if ($h) { $cible = [math]::Min($vb, (Get-DebitEchantillon $h $CrfPlafond)); $pourquoi = "le CRF $CrfPlancher tient dans la limite" }
      else { $h = $echelle[-1]; $cible = $vb; $pourquoi = 'limite très serrée : plus basse résolution, tout le budget' }
      $cible = [math]::Max($cible, 150000)

      for ($essai = 1; $essai -le 2; $essai++) {
        $kb = [int]($cible / 1000)
        $v = @('-vf', (Get-Filtre $h), '-c:v', 'libx264', '-preset', 'slow', '-b:v', "${kb}k", '-maxrate', "$([int]($kb * 1.6))k",
          '-bufsize', "$($kb * 3)k", '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-passlogfile', (Join-Path $travail 'passe'))
        & $ffmpeg -y -hide_banner -loglevel error -i $src @v -pass 1 -an -f mp4 $nulDev
        & $ffmpeg -y -hide_banner -loglevel error -i $src @v -pass 2 @aArgs -movflags +faststart $tmp
        if ((Get-Item -LiteralPath $tmp).Length -le $LimiteMo * 1MB) { break }
        $cible = $cible * 0.93                  # filet de sécurité : dépassement -> 7 % de moins
      }
      $comment = "réencodée en ${h}p, vidéo $([int]($cible / 1000)) kb/s ($pourquoi)"
    }
    if ((Get-Item -LiteralPath $tmp).Length -gt $LimiteMo * 1MB) { $comment += " ; ATTENTION : dépasse encore la limite de $LimiteMo Mo, propose un extrait plus court" }
    Move-Item -LiteralPath $tmp -Destination $sortie -Force
    Write-Host ("{0,-8} : {1}  ({2:N2} Mo)  {3}" -f $Pour.ToUpper(), $sortie, ((Get-Item -LiteralPath $sortie).Length / 1MB), $comment)
  }
} finally {
  Remove-Item -LiteralPath $travail -Recurse -Force -ErrorAction SilentlyContinue
}
