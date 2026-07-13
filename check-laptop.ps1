# ============================================================
#  CHECK-LAPTOP.PS1
#  Diagnostic complet d'un ordinateur portable Windows
#  Objectif : detecter les defauts caches avant/juste apres achat
#
#  UTILISATION :
#    1. Clic droit sur le fichier -> "Executer avec PowerShell"
#       (ou ouvrir PowerShell EN ADMINISTRATEUR puis lancer le script)
#    2. Si Windows bloque le script (execution policy), lancer d'abord :
#       Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#    3. Un rapport texte est genere sur le Bureau a la fin.
# ============================================================

$ErrorActionPreference = "SilentlyContinue"
$reportPath = "$env:USERPROFILE\Desktop\rapport-diagnostic-$(Get-Date -Format 'yyyy-MM-dd_HHmm').txt"
$report = @()

function Write-Section($title) {
    $line = "`n===== $title ====="
    Write-Host $line -ForegroundColor Cyan
    $script:report += $line
}

function Log($text) {
    Write-Host $text
    $script:report += $text
}

function Log-Warn($text) {
    Write-Host $text -ForegroundColor Yellow
    $script:report += "[A VERIFIER] $text"
}

# ============================================================
#  FONCTIONS DE TEST INTERACTIF (ecran / clavier / ports)
# ============================================================

function Test-Ecran {
    param([System.Windows.Forms.Screen]$Screen = [System.Windows.Forms.Screen]::PrimaryScreen)

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $colors = @(
        @{Name='Blanc'; Color=[System.Drawing.Color]::White},
        @{Name='Noir';  Color=[System.Drawing.Color]::Black},
        @{Name='Rouge'; Color=[System.Drawing.Color]::Red},
        @{Name='Vert';  Color=[System.Drawing.Color]::Lime},
        @{Name='Bleu';  Color=[System.Drawing.Color]::Blue},
        @{Name='Gris';  Color=[System.Drawing.Color]::Gray}
    )
    $script:colorIndex = 0
    $script:showGrid = $false

    $form = New-Object System.Windows.Forms.Form
    $form.StartPosition = 'Manual'
    $form.Location = $Screen.Bounds.Location
    $form.Size = $Screen.Bounds.Size
    $form.FormBorderStyle = 'None'
    $form.TopMost = $true
    $form.KeyPreview = $true
    $form.BackColor = $colors[0].Color
    $form.Cursor = [System.Windows.Forms.Cursors]::Cross

    $label = New-Object System.Windows.Forms.Label
    $label.AutoSize = $true
    $label.ForeColor = [System.Drawing.Color]::Gray
    $label.Font = New-Object System.Drawing.Font('Consolas', 13)
    $label.Text = "ESPACE = couleur suivante | G = grille pixels morts | ECHAP = quitter | Couleur : $($colors[0].Name)"
    $label.Location = New-Object System.Drawing.Point(20,20)
    $form.Controls.Add($label)

    $form.Add_Paint({
        param($s,$e)
        if ($script:showGrid) {
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
            for ($x = 0; $x -lt $form.Width; $x += 10)  { $e.Graphics.DrawLine($pen, $x, 0, $x, $form.Height) }
            for ($y = 0; $y -lt $form.Height; $y += 10) { $e.Graphics.DrawLine($pen, 0, $y, $form.Width, $y) }
        }
    })

    $form.Add_KeyDown({
        param($s,$e)
        if ($e.KeyCode -eq 'Escape') {
            $form.Close()
        } elseif ($e.KeyCode -eq 'Space') {
            $script:colorIndex = ($script:colorIndex + 1) % $colors.Count
            $script:showGrid = $false
            $form.BackColor = $colors[$script:colorIndex].Color
            $label.Text = "ESPACE = couleur suivante | G = grille pixels morts | ECHAP = quitter | Couleur : $($colors[$script:colorIndex].Name)"
            $form.Invalidate()
        } elseif ($e.KeyCode -eq 'G') {
            $script:showGrid = -not $script:showGrid
            $form.Invalidate()
        }
    })

    Write-Host "Fenetre plein ecran ouverte sur : $($Screen.DeviceName) ($($Screen.Bounds.Width)x$($Screen.Bounds.Height)). Regarde chaque coin/bord attentivement (idealement dans une piece sombre pour le noir)." -ForegroundColor Cyan
    [void]$form.ShowDialog()
}

function Test-Clavier {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $rows = @(
        @(@{L='Echap';K=[System.Windows.Forms.Keys]::Escape},@{L='F1';K=[System.Windows.Forms.Keys]::F1},@{L='F2';K=[System.Windows.Forms.Keys]::F2},@{L='F3';K=[System.Windows.Forms.Keys]::F3},@{L='F4';K=[System.Windows.Forms.Keys]::F4},@{L='F5';K=[System.Windows.Forms.Keys]::F5},@{L='F6';K=[System.Windows.Forms.Keys]::F6},@{L='F7';K=[System.Windows.Forms.Keys]::F7},@{L='F8';K=[System.Windows.Forms.Keys]::F8},@{L='F9';K=[System.Windows.Forms.Keys]::F9},@{L='F10';K=[System.Windows.Forms.Keys]::F10},@{L='F11';K=[System.Windows.Forms.Keys]::F11},@{L='F12';K=[System.Windows.Forms.Keys]::F12}),
        @(@{L='2/~';K=[System.Windows.Forms.Keys]::Oem3},@{L='1';K=[System.Windows.Forms.Keys]::D1},@{L='2';K=[System.Windows.Forms.Keys]::D2},@{L='3';K=[System.Windows.Forms.Keys]::D3},@{L='4';K=[System.Windows.Forms.Keys]::D4},@{L='5';K=[System.Windows.Forms.Keys]::D5},@{L='6';K=[System.Windows.Forms.Keys]::D6},@{L='7';K=[System.Windows.Forms.Keys]::D7},@{L='8';K=[System.Windows.Forms.Keys]::D8},@{L='9';K=[System.Windows.Forms.Keys]::D9},@{L='0';K=[System.Windows.Forms.Keys]::D0},@{L='-';K=[System.Windows.Forms.Keys]::OemMinus},@{L='=';K=[System.Windows.Forms.Keys]::Oemplus},@{L='Retour arriere';K=[System.Windows.Forms.Keys]::Back}),
        @(@{L='Tab';K=[System.Windows.Forms.Keys]::Tab},@{L='Q';K=[System.Windows.Forms.Keys]::Q},@{L='W';K=[System.Windows.Forms.Keys]::W},@{L='E';K=[System.Windows.Forms.Keys]::E},@{L='R';K=[System.Windows.Forms.Keys]::R},@{L='T';K=[System.Windows.Forms.Keys]::T},@{L='Y';K=[System.Windows.Forms.Keys]::Y},@{L='U';K=[System.Windows.Forms.Keys]::U},@{L='I';K=[System.Windows.Forms.Keys]::I},@{L='O';K=[System.Windows.Forms.Keys]::O},@{L='P';K=[System.Windows.Forms.Keys]::P},@{L='[';K=[System.Windows.Forms.Keys]::OemOpenBrackets},@{L=']';K=[System.Windows.Forms.Keys]::OemCloseBrackets},@{L='\';K=[System.Windows.Forms.Keys]::OemPipe}),
        @(@{L='Verr.Maj';K=[System.Windows.Forms.Keys]::CapsLock},@{L='A';K=[System.Windows.Forms.Keys]::A},@{L='S';K=[System.Windows.Forms.Keys]::S},@{L='D';K=[System.Windows.Forms.Keys]::D},@{L='F';K=[System.Windows.Forms.Keys]::F},@{L='G';K=[System.Windows.Forms.Keys]::G},@{L='H';K=[System.Windows.Forms.Keys]::H},@{L='J';K=[System.Windows.Forms.Keys]::J},@{L='K';K=[System.Windows.Forms.Keys]::K},@{L='L';K=[System.Windows.Forms.Keys]::L},@{L=';';K=[System.Windows.Forms.Keys]::OemSemicolon},@{L="'";K=[System.Windows.Forms.Keys]::OemQuotes},@{L='Entree';K=[System.Windows.Forms.Keys]::Return}),
        @(@{L='Maj G';K=[System.Windows.Forms.Keys]::LShiftKey},@{L='Z';K=[System.Windows.Forms.Keys]::Z},@{L='X';K=[System.Windows.Forms.Keys]::X},@{L='C';K=[System.Windows.Forms.Keys]::C},@{L='V';K=[System.Windows.Forms.Keys]::V},@{L='B';K=[System.Windows.Forms.Keys]::B},@{L='N';K=[System.Windows.Forms.Keys]::N},@{L='M';K=[System.Windows.Forms.Keys]::M},@{L=',';K=[System.Windows.Forms.Keys]::Oemcomma},@{L='.';K=[System.Windows.Forms.Keys]::OemPeriod},@{L='/';K=[System.Windows.Forms.Keys]::OemQuestion},@{L='Maj D';K=[System.Windows.Forms.Keys]::RShiftKey}),
        @(@{L='Ctrl G';K=[System.Windows.Forms.Keys]::LControlKey},@{L='Win G';K=[System.Windows.Forms.Keys]::LWin},@{L='Alt G';K=[System.Windows.Forms.Keys]::LMenu},@{L='Espace';K=[System.Windows.Forms.Keys]::Space},@{L='AltGr';K=[System.Windows.Forms.Keys]::RMenu},@{L='Win D';K=[System.Windows.Forms.Keys]::RWin},@{L='Menu';K=[System.Windows.Forms.Keys]::Apps},@{L='Ctrl D';K=[System.Windows.Forms.Keys]::RControlKey}),
        @(@{L='Inser';K=[System.Windows.Forms.Keys]::Insert},@{L='Origine';K=[System.Windows.Forms.Keys]::Home},@{L='Pg.Prec';K=[System.Windows.Forms.Keys]::Prior},@{L='Suppr';K=[System.Windows.Forms.Keys]::Delete},@{L='Fin';K=[System.Windows.Forms.Keys]::End},@{L='Pg.Suiv';K=[System.Windows.Forms.Keys]::Next}),
        @(@{L='GAUCHE';K=[System.Windows.Forms.Keys]::Left},@{L='HAUT';K=[System.Windows.Forms.Keys]::Up},@{L='BAS';K=[System.Windows.Forms.Keys]::Down},@{L='DROITE';K=[System.Windows.Forms.Keys]::Right})
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Test clavier - appuie sur chaque touche du clavier physique'
    $form.Size = New-Object System.Drawing.Size(1000, 660)
    $form.StartPosition = 'CenterScreen'
    $form.KeyPreview = $true
    $form.BackColor = [System.Drawing.Color]::White

    $info = New-Object System.Windows.Forms.Label
    $info.Text = "Appuie sur TOUTES les touches une par une. Chaque bouton devient VERT une fois detecte et le reste (suivi de progression). Le nommage suit la disposition interne Windows : sur un clavier AZERTY le bouton qui s'allume peut ne pas correspondre a la lettre gravee sur la touche, ce qui compte c'est qu'UN bouton s'allume a chaque pression."
    $info.Size = New-Object System.Drawing.Size(960, 45)
    $info.Location = New-Object System.Drawing.Point(10,10)
    $form.Controls.Add($info)

    $counter = New-Object System.Windows.Forms.Label
    $counter.AutoSize = $true
    $counter.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    $counter.Location = New-Object System.Drawing.Point(10, 58)
    $form.Controls.Add($counter)

    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = 'Fermer'
    $closeBtn.Location = New-Object System.Drawing.Point(880, 53)
    $closeBtn.Add_Click({ $form.Close() })
    $form.Controls.Add($closeBtn)

    $buttonsByKey = @{}
    $tested = New-Object System.Collections.Generic.HashSet[string]
    $totalKeys = 0
    $top = 95

    foreach ($row in $rows) {
        $left = 10
        foreach ($k in $row) {
            $btn = New-Object System.Windows.Forms.Button
            $btn.Text = $k.L
            $btn.Width = 62
            $btn.Height = 42
            $btn.Location = New-Object System.Drawing.Point($left, $top)
            $btn.BackColor = [System.Drawing.Color]::LightGray
            $btn.TabStop = $false
            $btn.Font = New-Object System.Drawing.Font('Segoe UI', 8)
            $form.Controls.Add($btn)
            $buttonsByKey[[int]$k.K] = $btn
            $totalKeys++
            $left += 66
        }
        $top += 47
    }
    $counter.Text = "Touches detectees : 0 / $totalKeys"

    $form.Add_KeyDown({
        param($s,$e)
        $keyInt = [int]$e.KeyCode
        if ($buttonsByKey.ContainsKey($keyInt)) {
            $buttonsByKey[$keyInt].BackColor = [System.Drawing.Color]::LightGreen
            [void]$tested.Add($keyInt.ToString())
            $counter.Text = "Touches detectees : $($tested.Count) / $totalKeys"
        }
        $e.Handled = $true
    })

    [void]$form.ShowDialog()
}

function Test-Ports {
    Write-Host "`nBranche successivement un peripherique DIFFERENT dans CHAQUE port disponible, un par un :" -ForegroundColor Cyan
    Write-Host "  - Cle USB / souris USB dans chaque port USB (gauche, droite, USB-C)" -ForegroundColor Cyan
    Write-Host "  - Cable HDMI/DisplayPort vers un ecran ou une TV si possible" -ForegroundColor Cyan
    Write-Host "  - Carte SD si lecteur present" -ForegroundColor Cyan
    Write-Host "Chaque peripherique detecte s'affiche ci-dessous avec l'heure exacte -> ca confirme que le port fonctionne." -ForegroundColor Cyan
    Write-Host "(le port jack audio ne peut pas etre confirme ainsi : teste-le en ecoutant un son au casque)`n" -ForegroundColor Yellow

    $sourceId = "PortTestListener_$(Get-Random)"
    try {
        Register-WmiEvent -Query "SELECT * FROM __InstanceCreationEvent WITHIN 2 WHERE TargetInstance ISA 'Win32_PnPEntity'" -SourceIdentifier $sourceId -Action {
            $device = $Event.SourceEventArgs.NewEvent.TargetInstance
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Peripherique detecte -> $($device.Name)" -ForegroundColor Green
        } | Out-Null

        Read-Host "Appuie sur Entree quand tu as fini de tester tous les ports"
    } finally {
        Get-EventSubscriber -SourceIdentifier $sourceId -ErrorAction SilentlyContinue | Unregister-Event
        Get-Job | Where-Object { $_.Name -eq $sourceId } | Remove-Job -Force -ErrorAction SilentlyContinue
    }
}

function Test-GPU-NVIDIA {
    $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if (-not $nvidiaSmi) {
        Write-Host "nvidia-smi introuvable (pilote NVIDIA absent ou pas dans le PATH)." -ForegroundColor Yellow
        return
    }
    Write-Host "`nReleve GPU NVIDIA en direct - Ctrl+C pour arreter :" -ForegroundColor Cyan
    & nvidia-smi --query-gpu=name,temperature.gpu,fan.speed,utilization.gpu,memory.used,memory.total,power.draw --format=csv -l 2
}

function Test-Ventilateurs {
    Write-Host "`n-- Etat ventilateurs (via WMI standard) --" -ForegroundColor Cyan
    $fans = Get-CimInstance Win32_Fan -ErrorAction SilentlyContinue
    if ($fans) {
        $fans | ForEach-Object { Write-Host "Ventilateur : $($_.Name) - Statut = $($_.Status) - Vitesse desiree = $($_.DesiredSpeed)" }
    } else {
        Write-Host "Aucune donnee ventilateur exposee via WMI standard (tres courant sur les laptops ASUS ROG, l'EC ne l'expose pas nativement a Windows)." -ForegroundColor Yellow
    }
    Write-Host "Sur un Zephyrus Duo, le RPM reel des 2 ventilateurs (CPU + GPU) et leurs courbes passent par le controleur embarque (EC) de la carte mere." -ForegroundColor Yellow
    Write-Host "C'est lisible de facon fiable uniquement via ASUS Armoury Crate (deja installe normalement) ou l'outil gratuit HWiNFO64 (capteurs EC)." -ForegroundColor Yellow
    Write-Host "Ce script ne pilote volontairement PAS l'EC directement (lecture/ecriture bas niveau des ports materiels) : mal fait, ca peut casser le controle des ventilateurs. Hors de portee ici par securite." -ForegroundColor Yellow
}

function Test-EvenementsMateriels {
    param([int]$Jours = 30)
    $since = (Get-Date).AddDays(-$Jours)
    Write-Host "`nRecherche d'erreurs materielles dans les journaux Windows (derniers $Jours jours)..." -ForegroundColor Cyan

    Write-Host "`n-- WHEA-Logger (erreurs materielles CPU / RAM / PCIe / chipset - carte mere) --"
    $whea = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WHEA-Logger'; StartTime=$since} -ErrorAction SilentlyContinue
    if ($whea) {
        Write-Host "$($whea.Count) evenement(s) WHEA trouve(s) - INDICE DE PROBLEME MATERIEL :" -ForegroundColor Red
        $whea | Select-Object -First 10 TimeCreated, Id | Format-Table -AutoSize
    } else {
        Write-Host "Aucun evenement WHEA -> bon signe (pas d'erreur materielle corrigee/non corrigee sur cette periode)." -ForegroundColor Green
    }

    Write-Host "`n-- Kernel-Power ID 41 (coupures brutales - souvent alimentation ou carte mere) --"
    $kp = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Kernel-Power'; Id=41; StartTime=$since} -ErrorAction SilentlyContinue
    if ($kp) {
        Write-Host "$($kp.Count) coupure(s) brutale(s) detectee(s) :" -ForegroundColor Red
        $kp | Select-Object -First 10 TimeCreated | Format-Table -AutoSize
    } else {
        Write-Host "Aucune coupure brutale detectee." -ForegroundColor Green
    }

    Write-Host "`n-- Reset/plantage pilote GPU (Event ID 4101, source Display - instabilite carte graphique) --"
    $gpuCrash = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Display'; Id=4101; StartTime=$since} -ErrorAction SilentlyContinue
    if ($gpuCrash) {
        Write-Host "$($gpuCrash.Count) plantage(s)/reset(s) pilote GPU detecte(s) :" -ForegroundColor Red
        $gpuCrash | Select-Object -First 10 TimeCreated | Format-Table -AutoSize
    } else {
        Write-Host "Aucun crash pilote GPU detecte." -ForegroundColor Green
    }

    Write-Host "`n-- Ecrans bleus / BugCheck --"
    $bsod = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WER-SystemErrorReporting'; Id=1001; StartTime=$since} -ErrorAction SilentlyContinue
    if ($bsod) {
        Write-Host "$($bsod.Count) ecran(s) bleu(s) trouve(s) :" -ForegroundColor Red
        $bsod | Select-Object -First 10 TimeCreated, Id | Format-Table -AutoSize
    } else {
        Write-Host "Aucun ecran bleu recent detecte." -ForegroundColor Green
    }
}

function Test-Charge {
    param([int]$DureeSecondes = 60)
    Write-Host "`nTest de charge CPU pendant $DureeSecondes secondes sur tous les coeurs (revele instabilites thermiques/electriques). Ctrl+C pour arreter avant." -ForegroundColor Cyan
    $cores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
    $jobs = 1..$cores | ForEach-Object {
        Start-Job -ScriptBlock {
            param($dur)
            $end = (Get-Date).AddSeconds($dur)
            while ((Get-Date) -lt $end) { [void][math]::Sqrt([math]::Pow((Get-Random -Maximum 999999), 2)) }
        } -ArgumentList $DureeSecondes
    }
    $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $DureeSecondes) {
        if ($nvidiaSmi) { & nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw --format=csv,noheader }
        Start-Sleep -Seconds 3
    }
    $jobs | Wait-Job | Out-Null
    $jobs | Remove-Job -Force
    Write-Host "`nTest de charge termine. Verification des evenements materiels sur les dernieres 24h pour voir si le stress a revele un probleme :" -ForegroundColor Cyan
    Test-EvenementsMateriels -Jours 1
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ATTENTION : le script n'est pas lance en administrateur." -ForegroundColor Red
    Write-Host "Certaines infos (sante disque, benchmark) seront incompletes.`n" -ForegroundColor Red
}

# ---------- 1. INFOS SYSTEME GENERALES ----------
Write-Section "SYSTEME"
$cs  = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$os  = Get-CimInstance Win32_OperatingSystem
Log "Modele        : $($cs.Manufacturer) $($cs.Model)"
Log "Numero serie  : $($bios.SerialNumber)"
Log "Date BIOS     : $($bios.ReleaseDate)"
Log "Windows       : $($os.Caption) (build $($os.BuildNumber))"
Log "Date install  : $($os.InstallDate)"

# ---------- 2. PROCESSEUR ----------
Write-Section "PROCESSEUR (CPU)"
$cpu = Get-CimInstance Win32_Processor
Log "Modele        : $($cpu.Name)"
Log "Coeurs/Threads: $($cpu.NumberOfCores) coeurs / $($cpu.NumberOfLogicalProcessors) threads"
Log "Vitesse       : $($cpu.MaxClockSpeed) MHz"
Log "Charge actu.  : $($cpu.LoadPercentage) %"

# ---------- 3. MEMOIRE (RAM) ----------
Write-Section "MEMOIRE (RAM)"
$mem = Get-CimInstance Win32_PhysicalMemory
$totalRamGB = [math]::Round(($mem | Measure-Object -Property Capacity -Sum).Sum / 1GB, 1)
Log "RAM totale    : $totalRamGB GB sur $($mem.Count) barrette(s)"
foreach ($m in $mem) {
    $sizeGB = [math]::Round($m.Capacity / 1GB, 1)
    Log "  - Slot $($m.DeviceLocator) : $sizeGB GB @ $($m.Speed) MHz ($($m.Manufacturer))"
}
Log-Warn "Pour tester la fiabilite reelle de la RAM (bits defectueux), lancer manuellement : mdsched.exe (Diagnostic de memoire Windows) puis redemarrer."

# ---------- 4. STOCKAGE (DISQUE) ----------
Write-Section "STOCKAGE (Disque / SSD)"
Get-CimInstance Win32_DiskDrive | ForEach-Object {
    $sizeGB = [math]::Round($_.Size / 1GB, 1)
    Log "Disque : $($_.Model) - $sizeGB GB - Interface $($_.InterfaceType)"
}
Log ""
try {
    Get-PhysicalDisk | ForEach-Object {
        $health = $_.HealthStatus
        $status = $_.OperationalStatus
        $line = "Etat sante physique : $($_.FriendlyName) -> Sante = $health / Statut = $status"
        if ($health -ne "Healthy") { Log-Warn $line } else { Log $line }
    }
} catch {
    Log-Warn "Impossible de lire l'etat SMART detaille (necessite droits admin)."
}
Log ""
Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object {
    $freeGB = [math]::Round($_.SizeRemaining / 1GB, 1)
    $totalGB = [math]::Round($_.Size / 1GB, 1)
    Log "Volume $($_.DriveLetter): $freeGB GB libres / $totalGB GB - Sante systeme fichiers : $($_.HealthStatus)"
}

# ---------- 5. BATTERIE ----------
Write-Section "BATTERIE"
try {
    powercfg /batteryreport /output "$env:USERPROFILE\Desktop\rapport-batterie.html" | Out-Null
    Log "Rapport detaille genere : rapport-batterie.html sur le Bureau (ouvre-le dans un navigateur)."
} catch {
    Log-Warn "Impossible de generer le rapport batterie (powercfg)."
}
try {
    $battStatic = Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData
    $battFull   = Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity
    if ($battStatic -and $battFull) {
        $design = $battStatic.DesignedCapacity
        $full   = $battFull.FullChargedCapacity
        $wear   = [math]::Round((1 - ($full / $design)) * 100, 1)
        Log "Capacite d'origine : $design mWh"
        Log "Capacite actuelle  : $full mWh"
        if ($wear -gt 15) {
            Log-Warn "Usure batterie estimee : $wear % (suspect si l'ordi est cense etre neuf ou tres peu utilise)"
        } else {
            Log "Usure batterie estimee : $wear % (normal)"
        }
    }
} catch {
    Log-Warn "Details capacite batterie non disponibles sur ce modele - se fier au rapport HTML genere ci-dessus."
}

# ---------- 6. CARTE GRAPHIQUE (GPU) ----------
Write-Section "CARTE GRAPHIQUE (GPU)"
Get-CimInstance Win32_VideoController | ForEach-Object {
    Log "GPU : $($_.Name) - Pilote v$($_.DriverVersion) du $($_.DriverDate)"
}

# ---------- 7. ECRAN ----------
Write-Section "ECRAN"
Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.Screen]::PrimaryScreen
Log "Resolution detectee : $($screen.Bounds.Width) x $($screen.Bounds.Height)"
Log-Warn "Test visuel obligatoire (pixels morts / bandes / backlight bleed) : ouvrir un navigateur en plein ecran sur un fond UNI blanc, puis noir, rouge, vert, bleu. Regarder chaque coin de l'ecran dans une piece sombre pour le noir."

# ---------- 8. RESEAU (WiFi / Ethernet / Bluetooth) ----------
Write-Section "RESEAU"
Get-NetAdapter | ForEach-Object {
    Log "$($_.Name) : $($_.InterfaceDescription) - Statut = $($_.Status)"
}

# ---------- 9. PERIPHERIQUES USB CONNECTES ----------
Write-Section "PERIPHERIQUES USB"
Get-PnpDevice -Class USB | Where-Object { $_.Status -eq "OK" } | ForEach-Object {
    Log "  $($_.FriendlyName)"
}
Log-Warn "Teste chaque port USB physiquement avec une cle USB ou souris pour verifier qu'ils fonctionnent tous (gauche/droite/USB-C)."

# ---------- 10. WINDOWS UPDATE ----------
Write-Section "MISES A JOUR WINDOWS"
try {
    $updates = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0").Updates
    Log "Mises a jour en attente : $($updates.Count)"
} catch {
    Log-Warn "Impossible de verifier les mises a jour en attente."
}

# ---------- 11. ECRANS DETECTES (support multi-ecran / ScreenPad Plus) ----------
Write-Section "ECRANS DETECTES"
Add-Type -AssemblyName System.Windows.Forms
$screens = [System.Windows.Forms.Screen]::AllScreens
for ($i = 0; $i -lt $screens.Count; $i++) {
    $sc = $screens[$i]
    $tag = if ($sc.Primary) { "PRINCIPAL" } else { "SECONDAIRE (probable ScreenPad Plus si Zephyrus Duo)" }
    Log "Ecran $i [$tag] : $($sc.DeviceName) - $($sc.Bounds.Width)x$($sc.Bounds.Height) - position $($sc.Bounds.X),$($sc.Bounds.Y)"
}
if ($screens.Count -eq 1) {
    Log-Warn "Un seul ecran detecte. Si c'est un Zephyrus Duo, le ScreenPad Plus devrait apparaitre comme 2e ecran - verifier qu'il est allume (touche Fn dediee) et que le pilote/firmware ASUS est a jour."
}

# ---------- 12. CARTE GRAPHIQUE NVIDIA (releve instantane) ----------
Write-Section "CARTE GRAPHIQUE NVIDIA (releve instantane)"
$nvidiaSmiCheck = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($nvidiaSmiCheck) {
    $gpuData = & nvidia-smi --query-gpu=name,driver_version,temperature.gpu,fan.speed,utilization.gpu,memory.used,memory.total,power.draw --format=csv,noheader
    Log "GPU : $gpuData"
    Log-Warn "fan.speed peut afficher N/A sur GPU portable (non expose par le pilote NVIDIA sur laptop) - normal, voir section ventilateurs."
} else {
    Log-Warn "nvidia-smi introuvable - pilote NVIDIA pas installe ou pas dans le PATH."
}

# ---------- 13. VENTILATEURS (CPU + GPU) ----------
Write-Section "VENTILATEURS"
$fansCheck = Get-CimInstance Win32_Fan -ErrorAction SilentlyContinue
if ($fansCheck) {
    $fansCheck | ForEach-Object { Log "Ventilateur : $($_.Name) - Statut = $($_.Status)" }
} else {
    Log-Warn "Aucune donnee ventilateur exposee via WMI standard (normal sur ASUS ROG, l'EC n'expose pas ca a Windows sans logiciel constructeur)."
}
Log "Pour le RPM reel des 2 ventilateurs du Zephyrus Duo : utiliser ASUS Armoury Crate ou HWiNFO64 (lecture EC) - non automatisable ici sans risque pour le materiel."

# ---------- 14. EVENEMENTS MATERIELS (30 derniers jours) ----------
Write-Section "EVENEMENTS MATERIELS 30 JOURS (detecte instabilite carte mere / CPU / GPU / RAM)"
$since30 = (Get-Date).AddDays(-30)
$whea30 = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WHEA-Logger'; StartTime=$since30} -ErrorAction SilentlyContinue
if ($whea30) { Log-Warn "$($whea30.Count) erreur(s) materielle(s) WHEA trouvee(s) sur 30 jours - detail avec l'option 5 du menu plus bas." } else { Log "Aucune erreur WHEA sur 30 jours (bon signe)." }
$kp30 = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Kernel-Power'; Id=41; StartTime=$since30} -ErrorAction SilentlyContinue
if ($kp30) { Log-Warn "$($kp30.Count) coupure(s) brutale(s) sur 30 jours - detail avec l'option 5 du menu plus bas." } else { Log "Aucune coupure brutale sur 30 jours." }
$gpu30 = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Display'; Id=4101; StartTime=$since30} -ErrorAction SilentlyContinue
if ($gpu30) { Log-Warn "$($gpu30.Count) plantage(s) pilote GPU sur 30 jours - detail avec l'option 5 du menu plus bas." } else { Log "Aucun plantage pilote GPU sur 30 jours." }

# ---------- CHECKLIST MANUELLE (rien de tout ca ne peut etre automatise) ----------
Write-Section "CHECKLIST MANUELLE A FAIRE EN PLUS"
$manual = @(
"[ ] Clavier : tester TOUTES les touches (site type keyboardtester.com ou bloc-notes)",
"[ ] Trackpad : glisser, clic gauche/droit, multi-touch (pincer/zoomer)",
"[ ] Webcam : ouvrir l'app Camera Windows",
"[ ] Microphone : enregistrer un memo vocal",
"[ ] Haut-parleurs : jouer un son, verifier les deux cotes",
"[ ] Charnieres : ouvrir/fermer l'ecran plusieurs fois, verifier le jeu/mou",
"[ ] Chassis : appuyer legerement sur le clavier et le dessous, verifier l'absence de flex/craquement",
"[ ] Ventilateur : ecouter le bruit au demarrage et sous charge (bruit anormal, cliquetis)",
"[ ] Temperature : surveiller avec HWMonitor ou HWiNFO pendant 15-20 min d'usage normal",
"[ ] Lecteur d'empreinte / Windows Hello si presente",
"[ ] Port jack audio (casque)",
"[ ] Port HDMI/DisplayPort avec un ecran externe si possible"
)
$manual | ForEach-Object { Log $_ }

# ---------- EXPORT ----------
$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`n`nRapport complet sauvegarde ici :" -ForegroundColor Green
Write-Host $reportPath -ForegroundColor Green

# ---------- MENU TESTS INTERACTIFS ----------
Write-Host "`n`n===== TESTS INTERACTIFS (recommande) =====" -ForegroundColor Cyan
Write-Host "1 = Test ECRAN (choix principal ou ScreenPad Plus) - pixels morts / uniformite / backlight"
Write-Host "2 = Test CLAVIER (chaque touche s'allume quand detectee)"
Write-Host "3 = Test PORTS physiques en temps reel (USB / HDMI-DP / carte SD)"
Write-Host "4 = Test de charge CPU/GPU 60s + surveillance NVIDIA en direct + re-verif evenements materiels"
Write-Host "5 = Detail complet evenements materiels (WHEA / coupures / crash GPU / ecrans bleus)"
Write-Host "0 = Quitter"

do {
    $choice = Read-Host "`nTon choix"
    switch ($choice) {
        '1' {
            Add-Type -AssemblyName System.Windows.Forms
            $ecrans = [System.Windows.Forms.Screen]::AllScreens
            if ($ecrans.Count -gt 1) {
                Write-Host "Plusieurs ecrans detectes :"
                for ($i = 0; $i -lt $ecrans.Count; $i++) {
                    $tag = if ($ecrans[$i].Primary) { "principal" } else { "secondaire / ScreenPad Plus" }
                    Write-Host "  $i = $($ecrans[$i].DeviceName) ($tag, $($ecrans[$i].Bounds.Width)x$($ecrans[$i].Bounds.Height))"
                }
                $idx = Read-Host "Quel ecran tester (numero)"
                if ($idx -match '^\d+$' -and [int]$idx -lt $ecrans.Count) { Test-Ecran -Screen $ecrans[[int]$idx] } else { Test-Ecran }
            } else {
                Test-Ecran
            }
        }
        '2' { Test-Clavier }
        '3' { Test-Ports }
        '4' { Test-Charge -DureeSecondes 60 }
        '5' { Test-EvenementsMateriels -Jours 30 }
        '0' { Write-Host "Termine. Pense a comparer le rapport texte + le rapport-batterie.html sur le Bureau." -ForegroundColor Green }
        default { Write-Host "Choix invalide, entre 0 et 5." -ForegroundColor Yellow }
    }
} while ($choice -ne '0')

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nRapport final mis a jour : $reportPath" -ForegroundColor Green
