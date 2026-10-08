// Defaults for the Brother DS-740D sheet-fed scanner
module.exports = {
  afterDevices(devices) {
    devices
      .filter((d) => d.id.startsWith('brother5'))
      .forEach((device) => {
        const f = device.features;

        // Feed from the document feeder, both sides
        if (f['--source']) {
          const duplex = f['--source'].options.find((o) => o.includes('Duplex'));
          if (duplex) f['--source'].default = duplex;
        }

        // 300 dpi is plenty for OCR in Paperless
        if (f['--resolution']) f['--resolution'].default = 300;

        // Let the scanner crop to the page, straighten it and drop blank sides
        ['--AutoDocumentSize', '--AutoDeskew', '--SkipBlankPage'].forEach((name) => {
          if (f[name]) f[name].default = 'yes';
        });

        // Scan the whole stack in one go and output a single multi-page PDF
        const batch = device.settings.batchMode;
        const auto = batch.options.find((o) => o === 'auto');
        if (auto) batch.default = auto;

        const pipeline = device.settings.pipeline;
        const pdf = pipeline.options.find((o) => o.startsWith('PDF (JPG'));
        if (pdf) pipeline.default = pdf;
      });
  }
};
