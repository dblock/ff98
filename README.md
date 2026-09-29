# File & Folder 98

File & Folder 98 is a 1998 Windows document manager for Word documents. It was written by [Daniel Doubrovkine](https://github.com/dblock) (dB.) in Delphi 3, and published as shareware under Stolen Technologies Inc. (STI) and Vestris Inc. in Geneva. It succeeded an earlier Windows 3.11 version. The version string is `100160798`.

Instead of Explorer's tree of drives and folders, File & Folder shows **virtual volumes**. Each volume is a name, such as `UNIGE`, that points to a folder on any drive. The folders inside a volume are listed together with the Word documents they hold, and `.doc` extensions are hidden. A button bar down the left side has commands for the current folder and document.

## What It Does

* **Virtual volumes.** In **Setup**, you give a volume a name and pick its root folder. Volumes are stored in the registry under `HKCU\Software\Stolen Technologies Inc.\File & Folder 98\Volumes`.
* **Folders.** Create, rename and delete folders.
* **Documents.** Create, open, print, rename, delete, copy and move Word documents. **Open As** opens a copy of a document under a new name. **New Document** names the document from today's date and creates it in Word through OLE automation (`Word.Basic`).
* **Recent documents.** Each volume keeps a list of recently used documents, shown by **Choose from Recent**.
* **Properties.** Shows a document's size, dates and attributes, and lets you change the attributes.
* **Document Preview.** Shows the document as a page, embedded with an OLE container, with a zoom factor and scroll buttons.
* **Doc Text Preview.** Shows the plain text of a document. The text comes from `docdll.dll`, a small MFC C++ library that reads the Word file format directly. Its source is in [original/docdll/](original/docdll/).
* **Help.** A WinHelp user guide, `folder.hlp`.
* **Shareware expiry.** The program stops working 360 days after its first run.

## Layout

* [original/](original/) is the 1998 Delphi 3 source, unchanged. It also holds the 1998 build of `folder.exe`, `docdll.dll` and its source, the help file and its source in `help/`, and the InstallShield setup in `install/`.
* [ported/](ported/) is the same program, ported to build with Free Pascal and Lazarus (LCL).
  * `src/` holds the application: `folder.lpr`, the `.pas` units and text `.lfm` forms.
  * `compat/` holds small replacements for Delphi units that the LCL doesn't have.
  * `common.d32/` holds shared helper units, the same as in [inet98](https://github.com/dblock/inet98).
  * `bin/` holds the release build, `folder.exe`, plus `docdll.dll` and the help files it loads.
* [scripts/](scripts/) holds the scripts that install the toolchain, build and run the port on macOS.

## Building and Running

The original needs Windows 95 or 98, or a 32-bit Windows that can still run it, and Word for the OLE features. The port builds on macOS with the Windows (win32) version of Free Pascal and Lazarus running under Wine. It also runs under Wine.

```bash
scripts/setup.sh           # one-time: Wine + win32 Lazarus/FPC into ~/.cache/ff98 (~600 MB)
scripts/build.sh           # ported/bin/folder.exe
scripts/run.sh             # launch File & Folder 98 under Wine
```

A release build is committed in [ported/bin/](ported/bin/). To run it without building, install Wine and run `scripts/run.sh`, or run `wine folder.exe` from that folder.

Pass `--debug` to both `build.sh` and `run.sh` to build and run `folder-debug.exe`. It is a console build with line info that prints exceptions and their stack traces to the terminal. Set `FF98_TOOLS` to install the toolchain somewhere else. If [inet98](https://github.com/dblock/inet98) is already set up, `ln -s ~/.cache/inet98 ~/.cache/ff98` reuses its toolchain.

On the first run, File & Folder shows a welcome message and opens **Setup**. Add a volume that points to a folder with some `.doc` files, then press **Save**.

## Why the Original Doesn't Run

The 1998 `folder.exe` doesn't start under Wine on Apple Silicon. Wine runs 32-bit Windows programs there through WoW64, under Rosetta 2:

* With the default settings, it crashes inside `wow64cpu` on its first call to `GetDC`.
* With the Windows version set to Windows 98, it spins at 100% CPU and Rosetta reports that the local descriptor table (LDT) isn't supported.

Rebuilding the source with a current compiler avoids both problems.

## What It Took to Port

The toolchain and build scripts are the same as for [inet98](https://github.com/dblock/inet98). They use the Windows version of Free Pascal and Lazarus under Wine, so the Win32 API units and the Windows version of the LCL work as they are.

### Forms

* Delphi 3 saves forms as binary `.dfm` files. A small FPC program converted each one to a text `.lfm` file with `ObjectResourceToText`. The LCL reads the Delphi 3 image lists in them as they are.
* Properties that don't exist in the LCL were removed: `AllowAllUp`, `IncrementalDisplay` and `EditorEnabled`.
* Delphi doesn't save the `ModalResult`, `Default` and `Cancel` values that a `TBitBtn` gets from its `Kind`, and the LCL doesn't apply them when it loads a form. Without them, the OK and Cancel buttons of the folder chooser used by **Copy To** and **Move To** did nothing. They're now set in `FFSelect.lfm`.
* A `TSpeedButton` is transparent in the LCL, which showed the panel caption behind the logo. The logo buttons now set `Transparent = False`.

### Code

* `WinTypes` became `Windows`, `OleAuto` became `ComObj`, and `{$R *.DFM}` became `{$R *.lfm}`. The unused `Ole2`, `OleDlg` and CoolMenu units were removed.
* `folder.lpr` adds `Interfaces`, and an exception handler for the debug build.
* In `folder.dpr` the message box was the first form created. In the LCL the first form created becomes the main form, so closing a message box would quit the program. The message box is now created without becoming the main form.
* The custom directory list box, `FFDirListBox`, lost its `Ctl3D` and IME properties. `GetVolumeInformation` needed `DWORD` arguments, and a global function named `GetItemHeight` was renamed so it doesn't hide the LCL method of the same name.
* **Doc Text Preview** skipped the first character of every document and showed accented letters as `?`:
  * The loop over the text now starts at index 0.
  * `docdll.dll` returns Windows-1252 text, which is now converted to UTF-8 for the LCL.
* The message box removed its buttons without freeing them. A removed button stayed the form's default button, and the LCL crashed when the next dialog set a new one. The old buttons are now freed.
* Without Word, **New Document** showed the OLE error and then crashed on the empty object. It now stops after the error.
* **Help** called `Application.HelpCommand`, which does nothing in the LCL. It now calls `WinHelp`, and Wine's `winhlp32` opens the help file.
* The Delphi VCL's `BrowseDr` and `OleCtnrs` units aren't in the LCL. They're replaced by small versions in [ported/compat/](ported/compat/):
  * `TBrowseDirectoryDlg` wraps the LCL's `TSelectDirectoryDialog`.
  * Wine has no Word to embed, so `TOleContainer` draws the document's text on a white page, with the text from `docdll.dll`.

## License

File & Folder 98, its port and scripts are released under the [MIT License](LICENSE). The exception is `REGSTR.PAS` in [ported/common.d32/](ported/common.d32/), a Delphi Runtime Library unit that is © 1996 Borland International.

The 1998 help file and About box still carry the original shareware terms and Vestris Inc. notices. They're kept as historical text, and the MIT License replaces them. Trademarks belong to their respective owners.
