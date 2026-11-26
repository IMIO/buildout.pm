# Changelog

## 4.2.36rc8 (unreleased)

- Use branch `1.x` for `collective.behavior.talcondition` in `sources.cfg`.
- Products.PloneMeeting 4.2.29rc19
    - Items updated by batch action `UpdateProposingGroupBatchActionForm`
      are not considered modified (modification date is kept),
      added parameter `notify_modified=True` to `MeetingItem._update_after_edit`.
    - Renamed `PMConcatenateAnnexesBatchActionForm` to `PMExportPDFBatchActionForm`
      and batch action `concatenate-annexes-batch-action` to `export-pdf-batch-action`,
      based on `imio.annex` `ExportPDFBatchActionForm`.
      Annex types to export are no more selected, annexes to export are selected
      (and ordered) in a list of the annexes of selected items (annexes and decision
      annexes), coherent with the faceted `Annexes` and `Annex types` filters like it
      is the case for `PMDownloadElementsAnnexesBatchActionForm`, see vocabulary
      `Products.PloneMeeting.vocabularies.export_pdf_annexes_vocabulary`, non PDF
      annexes are disabled.  Logic shared with `PMDownloadElementsAnnexesBatchActionForm`
      is in `PMElementsAnnexesMixin`.
      Requires `imio.annex` with `ExportPDFBatchActionForm` (2.29.0+).
    - Adapted JS `itemExportPDF` as the `imio.annex` `ExportPDFForm` button
      `apply_export_pdf` (`Apply`) is renamed to `download_export_pdf` (`Download`),
      the item export PDF popup is closed when clicking on it.
      Requires `imio.annex` with `download_export_pdf` button (2.29.0+).
    - `PMSignersAdapter.get_discriminators` returns a tuple of strings as expected
      by `imio.esign` instead of the discriminators joined in a single string that was
      compared as a set of characters, so different discriminators made of the same
      characters (like UIDs) were using the same esign session.
      A `ValueError` is raised when `MeetingConfig.eSignDiscriminatorsTALExpr`
      does not return a tuple or a list of strings so the configuration is fixed,
      a returned list is turned into a tuple, default value is now `python: (cfg.getId(), )`.
    - Display item labels between item title and item reference in the `Files` column
      of `@@parapheo` (`@@esign-session-files`) like in the dashboards, labels and
      item reference are now rendered by the `@@static-infos` view.
      Fixed `@@static-infos` rendering an empty labels block for items that never had labels.
- imio.annex 2.29.0
    - Renamed `ConcatenateAnnexesBatchActionForm` to `ExportPDFBatchActionForm`
      for consistency with `ExportPDFForm`, the button msgid `concatenate-annexes-batch-action-but`
      is renamed to `export-pdf-batch-action-but` so the batch action view must be
      registered as `export-pdf-batch-action`.  Other `concatenate_annexes_*` msgids
      are renamed as well: `concatenate_annexes_batch_action_descr` to
      `export_pdf_batch_action_descr`, `concatenate_annexes_pdf_read_error` to
      `export_pdf_read_error` and `concatenate_annexes_pdf_too_large_error` to
      `export_pdf_too_large_error`.  Request keys `concatenate_annexes_item_pdf_error_url`
      (set when a PDF can not be read) and `concatenate_annexes_pdf_error_url`
      (returned by `render`) did not match, both are now `export_pdf_error_url`.
      Field `annex_types` is replaced by
      field `annexes` that works like `DownloadElementsAnnexesBatchActionForm.annexes`:
      it lists annexes of selected elements (not excluded by `_check_element`) using
      the vocabulary defined in `annexes_vocabulary` (`imio.annex.export_pdf_elements`
      by default, so non PDF and only previewable annexes are disabled), every
      selectable annexes are selected by default and it is sortable, annexes are
      exported in the selected order.  Max total size is checked on selected
      annexes.  Hooks `_annex_types_vocabulary` and `_element_annexes` were removed,
      use `annexes_vocabulary`, `_annexes_filters` or `_element_terms` instead.
      Logic managing field `annexes` is shared in `ElementsAnnexesMixin`.
    - Added `ExportZipForm`, the Zip counterpart of `ExportPDFForm` to download selected
      annexes of an element: needs to be registered as `@@export-zip-form` by the using
      applications. Zip writing moved to the `zip_annexes` and `unique_zip_path` functions,
      `ExportPDFForm` exports through the `_do_export` hook.
      Added `_default_annexes` and `_annex_from_term` hooks in `ElementsAnnexesMixin`.
    - `DownloadAnnexesBatchActionForm.do_zip` sets the Zip response headers once the
      Zip file is generated so the redirect done when zipping raises `LargeZipFile`
      is not served as `application/zip`.  `ExportZipForm` also manages `LargeZipFile`
      and displays an error instead of failing.
    - Zip logic shared by `DownloadAnnexesBatchActionForm` and `ExportZipForm` moved to
      `ZipAnnexesMixin`, so `ExportZipForm` gets the `_max_total_size`, `_zip_filename`,
      `_unique_zip_path` and `zipfiles` hooks.  `_total_size` and `do_zip` now take
      the `annexes` parameter, `do_zip` manages `LargeZipFile` and returns `None`
      in this case.  Added `_check_max_total_size(annexes)` that displays an error
      when max total size is exceeded.
    - Max total size check shared by `ZipAnnexesMixin` and `ExportPDFBatchActionForm`
      moved to `MaxTotalSizeMixin` (`_max_total_size`, `_total_size(annexes)` and
      `_check_max_total_size(annexes)`), the displayed error is defined by
      `too_large_error_msg`.
    - Fixed `export_pdf_batch_action_descr` French translation (wrong closing `<p>`
      tag, size limit is about selected annexes, greyed annexes explained) and
      removed the misleading "accept pop-ups" sentence from the Zip download
      description, the file is downloaded without opening a new window.
    - Fixed `export_pdf_descr` French translation (`ExportPDFForm`), use "export"
      wording, selectable elements are documents (not only annexes), explained that
      they may be reordered by drag and drop and that generating the PDF may take a
      few seconds, like for `export_pdf_batch_action_descr`.
    - `ExportPDFForm` (and so `ExportZipForm`) button `apply_export_pdf` (`Apply`)
      is renamed to `download_export_pdf` (`Download`, `collective.eeafaceted.batchactions`
      domain) like for `ExportPDFBatchActionForm`, so the button id is now
      `form-buttons-download_export_pdf`.
- imio.esign 1.0.6
    - Discriminators must be a tuple of strings, this is checked by `utils.check_discriminators`
      in `add_files_to_session`, `create_session` and `discriminate_sessions` that raise a
      `TypeError` otherwise. Discriminators are compared as sets so a string was compared as
      a set of characters and different strings made of the same characters (like UIDs) were
      added to the same session. `ISignable.get_discriminators` must return a tuple.
      Added `utils.get_session_discriminators` to get discriminators stored on a session
      as a tuple, sessions created before may store a list or a string.
- imio.pm.locales 4.2.34rc12
    - Added msgid `The "${field_title}" of meeting configuration "${cfg_title}" must return
      a tuple or a list of strings, returned value is "${value}"!` raised when
      `MeetingConfig.eSignDiscriminatorsTALExpr` returns a wrong value.
      Adapted `esign_discriminators_tal_expr_descr` (fr), the expression may return
      a tuple or a list, example is now `python: (cfg.getId(), )`.
- plonetheme.imioapps 2.70
    - Renamed `concatenate-annexes-batch-action` button icon style to
      `export-pdf-batch-action` as the batch action was renamed in `imio.annex`.
- plonemeeting.restapi 2.15
    - Fixed randomly failing tests: in `BaseTestCase.setUp`, call `gc.collect()`
      to release requests kept alive by reference cycles by previous tests
      (requests that ended with an exception), otherwise their skin data cleanup
      could happen in the middle of a next request, then set up skin data again.
    - Added GitHub Actions workflow to run tests, based on the
      `Products.MeetingCommunes` one (reusable `package-test-legacy` workflow).
      Use `Products.PloneMeeting` `master` branch in `buildout.cfg`.

