# Printing

We have one black-and-white laser printer (a **Ricoh SP 211**). It's shared over the network through the print server on the NAS, so you can print from your phone or computer without plugging anything in.

!!! info "Printer address"
`ipp://nas.main.internal:631/printers/RICOH_SP_211_GDI`

## From a phone

Printing from a phone works through the normal print option in most apps.

=== "Android"
Tap **Share / Print** in an app. Choose the printer named **RICOH_SP_211_GDI** if it's listed. If it isn't, add the printer by address in **Settings, Connected devices, Printing**.

=== "iPhone"
Tap **Share, Print**, then **Select Printer**. If the printer isn't listed, ask the person who runs the server to help add it.

## From a computer

Add a new printer using the address above (an **IPP** or **Internet Printing Protocol** printer). Use the generic **PostScript** or **driverless** option if asked for a driver, because the print server converts documents for the Ricoh.

## Tips

- It prints black and white only, on A4.
- The first page can take a little while to start while the printer wakes up.
- If nothing prints, check the printer is switched on, has paper, and wasn't left in sleep mode.

See [Troubleshooting](../help/troubleshooting.md) if it still doesn't work.
