# 3D printing

We have a Bambu Lab 3D printer. It lives in the **Comms Cupboard**, next to the printer and scanner. Bambuddy is the site for it.

## Bambuddy: print queue, control and filament

**Address:** <https://bambuddy.f9.casa>

Use Bambuddy to see the printer's status, queue prints and watch progress. It also keeps track of the filament spools (colour, type and roughly how much is left). Sign in with your house login.

## Sending prints from Bambu Studio

Bambuddy pretends to be a Bambu printer, so you can **Send** a sliced file from Bambu Studio (or OrcaSlicer) straight into the print queue. Set this up once on each computer.

!!! info "Details you'll need"
    - **Address:** `10.10.30.246` (you must be on the home network or the VPN)
    - **Access code:** ask Scott. It isn't written here because this documentation is public.

### Step 1: install the certificate (once per computer)

Bambuddy uses its own security certificate, so Bambu Studio has to be told to trust it. Without this, sending fails with `Connect failed! [code=-1]`.

1. Download the certificate: [bambuddy-virtual-printer-ca.pem](../assets/bambuddy-virtual-printer-ca.pem). Save it somewhere easy, such as your Downloads folder.
2. Close Bambu Studio completely.

=== "Windows"
    1. Open **Notepad++** or **VS Code** as administrator (right-click the app, then **Run as administrator**). Don't use plain Notepad, because it can damage the file.
    2. Open `C:\Program Files\Bambu Studio\resources\cert\printer.cer`.
    3. Make a backup first: save a copy next to it called `printer.cer.bak`.
    4. Open the downloaded `bambuddy-virtual-printer-ca.pem` in the same editor and copy **everything**, from `-----BEGIN CERTIFICATE-----` to `-----END CERTIFICATE-----`.
    5. In `printer.cer`, press **Ctrl+End** to go to the very end. If the last line isn't empty, press Enter once.
    6. Paste, then save.
    7. Start Bambu Studio again.

    For OrcaSlicer the file is at `C:\Program Files\OrcaSlicer\resources\cert\printer.cer`.

=== "macOS"
    Open **Terminal** and run these (change the path if the certificate isn't in Downloads):

    ```sh
    CERT=/Applications/BambuStudio.app/Contents/Resources/cert/printer.cer
    cp -v "$CERT" "$CERT.bak"
    sed -i '' '$a\' "$CERT"
    cat ~/Downloads/bambuddy-virtual-printer-ca.pem >> "$CERT"
    ```

    Then quit Bambu Studio fully (**Cmd+Q**) and open it again. For OrcaSlicer use `/Applications/OrcaSlicer.app/...` instead.

=== "Linux"
    Find the file first, because the location depends on how Bambu Studio was installed:

    ```sh
    find / -name printer.cer 2>/dev/null
    ```

    Then append the certificate (replace the path with the one you found):

    ```sh
    CERT=/path/to/printer.cer
    sudo cp -v "$CERT" "$CERT.bak"
    sudo sed -i '$a\' "$CERT"
    sudo tee -a "$CERT" < ~/Downloads/bambuddy-virtual-printer-ca.pem
    ```

    Restart Bambu Studio. AppImage versions can't be edited in place, so ask Scott for help.

!!! tip "Check it worked"
    On macOS or Linux, `openssl x509 -noout -subject -in ~/Downloads/bambuddy-virtual-printer-ca.pem` should show `CN=Virtual Printer CA`. The file you appended to should end with the same text.

### Step 2: add the printer

1. In Bambu Studio open the **Device** tab and choose **Add printer**.
2. Choose **Add printer by IP** (or **Bind with access code**).
3. Enter the address `10.10.30.246` and the access code from Scott.
4. Confirm. The printer should now appear.

If you are on the home Wi-Fi, the printer may also appear in the list by itself. Just select it and enter the access code.

### Step 3: send a print

Slice as normal, then press **Send** (not **Print**). The file lands in Bambuddy, where it can be checked and added to the queue.

### If it doesn't work

- `Connect failed! [code=-1]` means the certificate step didn't work. Check you used the file Scott gave you, that the text was pasted right at the **end** of `printer.cer`, and that you fully restarted Bambu Studio.
- Updating Bambu Studio can replace `printer.cer`, so you may need to repeat step 1 after an update.
- Scott may need to reissue the certificate if Bambuddy is reinstalled or moved. If it suddenly stops working, ask.

## Before you print

1. Check that the filament you need is loaded (see the filament section in Bambuddy).
2. Check the build plate is clear and clean. The printer is in the Comms Cupboard.
3. Start the print and don't leave it running unattended for long jobs.

When a print finishes, Home Assistant sends a "ready to collect" alert.

!!! warning "Never leave a long print unattended"
    3D printers get hot. If you see anything strange (smoke, a smell, noise), stop the print and switch it off at the wall.
