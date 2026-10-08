# Printing

We have one black-and-white laser printer (a **Ricoh SP 211**). It sits in the **Comms Cupboard**, next to the scanner and the 3D printer, and is shared over the network, so you can print from your phone or computer without plugging anything in.

!!! info "Printer address"
`http://nas.main.internal:631/printers/RICOH_SP_211_GDI`

    (Apps that ask for an IPP address can use the same thing starting with `ipp://` instead of `http://`.)

## From an Android phone

Some phones, such as the OnePlus Open, have no printing built in. Install the **CUPS Printing** app first.

<p class="store-badges">
<a href="https://play.google.com/store/apps/details?id=io.github.benoitduffez.cupsprint"><img src="../../assets/badges/google-play.png" alt="Get it on Google Play"></a>
</p>

1. Install **CUPS Printing**, then open your phone's **Settings** and search for **Printing**.
2. Switch on **CUPS Printing**.
3. Add the printer with the address above.
4. From any app, tap **Share / Print** and choose the printer.

## From an iPhone or iPad

Tap **Share, Print**, then **Select Printer**. If the printer isn't listed, ask Scott to help add it.

## From a Windows computer

1. Open **Settings, Bluetooth & devices, Printers & scanners**.
2. Click **Add device**, wait a moment, then click **Add manually**.
3. Choose **Select a shared printer by name** and paste in:

    ```text
    http://nas.main.internal:631/printers/RICOH_SP_211_GDI
    ```

4. Click **Next**. If Windows asks for a driver, choose **Microsoft IPP Class Driver** (or **Generic / Text Only** if that's not offered), then click **Next** and **Finish**.
5. Print a test page.

## From a Mac

Open **System Settings, Printers & Scanners, Add Printer**, then the **IP** tab. Set the protocol to **IPP**, the address to `nas.main.internal:631`, the queue to `printers/RICOH_SP_211_GDI`, and click **Add**.

## Tips

- It prints black and white only, on A4.
- The first page can take a little while to start while the printer wakes up.
- If nothing prints, check the printer is switched on, has paper, and wasn't left in sleep mode. It's in the Comms Cupboard.

See [Troubleshooting](../help/troubleshooting.md) if it still doesn't work.
