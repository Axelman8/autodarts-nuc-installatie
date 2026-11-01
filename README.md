# Herstel Autodarts Play op een Ubuntu NUC

Voor een x86-64 NUC met Ubuntu waarop Chromium na een update `play.autodarts.com` niet meer opent. Dit pakket installeert Google Chrome en start Autodarts Play bij de volgende aanmelding schermvullend. Het bestaande Autodarts-board en de cameraconfiguratie blijven bewaard.

## Installeren op de NUC

1. [Download het herstelbestand](https://github.com/Axelman8/autodarts-nuc-herstel/releases/latest/download/herstel-autodarts-kiosk.sh) op de NUC. Sla het op in **Downloads**.
2. Open **Terminal** en voer uit:

   ```bash
   sudo bash ~/Downloads/herstel-autodarts-kiosk.sh
   ```

3. Vul het eigen Ubuntu-wachtwoord in en herstart de NUC. Meld je eenmalig aan bij Autodarts Play als de website daarom vraagt.

Gebruik de terminal als de NUC meerdere gebruikersaccounts heeft vanuit het account dat normaal Autodarts op het scherm toont. Een werkende internetverbinding is nodig voor de Chrome-installatie.

## Wat het herstel doet

- Installeert de officiële Google Chrome Stable voor Ubuntu x86-64.
- Bewaart bestaande Autodarts-browserstartbestanden in `~/autodarts-kiosk-backup-<datum>`.
- Laat Chrome automatisch in kioskmodus openen op `https://play.autodarts.com`.
- Zet de bestaande `autodarts.service` aan als die aanwezig is.
- Laat board-ID, API-sleutel, camera-instellingen en bestaande browserprofielen ongemoeid.

Het programma schakelt alleen Autodarts-gerelateerde browserstarters uit. Als de NUC nog om het Ubuntu-accountwachtwoord vraagt vóór het bureaublad verschijnt, moet automatisch aanmelden afzonderlijk worden ingesteld. Een account kan de eerste keer ook opnieuw bij Autodarts Play moeten inloggen omdat Chrome een eigen browserprofiel gebruikt. Met `--password-store=basic` kan Chrome deze aanmelding zonder een GNOME-sleutelbosvenster bewaren; de lokale browsergegevens zijn dan minder beschermd tegen iemand met toegang tot het Ubuntu-account.

## Controle

Na opnieuw opstarten moet Autodarts Play het scherm vullen. Staat er een foutpagina, controleer dan de internetverbinding met `curl -I https://play.autodarts.com`. Is de pagina zichtbaar maar worden worpen niet herkend, controleer dan `systemctl status autodarts` en de unieke board-koppeling van deze NUC.
