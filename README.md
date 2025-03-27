# iPortForwarder

A native macOS app built using SwiftUI and Rust, enables you to forward multiple remote ports to your local ports.

## Screenshot

![screenshot](./docs/screenshot.avif)

## Download

Go to the [GitHub Releases](https://github.com/hronro/iPortForwarder/releases) page.

## FAQ

<details>
	<summary>When you first open the app, macOS displays an error message stating, "Apple could not verify "iPortForwarder" is free of malware that may harm your Mac or compromise your privacy."</summary>
![Apple Fee Error](./docs/apple-fee-error.avif)
The only reason that this error comes out is that I did not pay the Apple Developers fee (99USD/year) to Apple, which I don't plan to pay in the near future.
If you are using macOS 12 to macOS 14, you can easily bypass this issue by right-clicking on "iPortForwarder.app" and selecting "Open" from the context menu. For macOS 15 and later, open the System Settings app, navigate to the "Privacy & Security" section, scroll to the bottom of the page, and click the "Open Anyway" button.
</details>

<details>
	<summary>Is it possible to save the ports forwarding list?</summary>
Yes. To save your current forwarding list, click on "File" in the menu bar and select "Save Current Forwarding List." Alternatively, you can press <kbd>⌘</kbd> + <kbd>S</kbd>. Choose a location to save the file.

To load a saved list, go to "File" in the menu bar and choose "Import Forwarding List." You can also use the shortcut <kbd>⌘</kbd> + <kbd>O</kbd>. Select the file that you previously saved.

![screenshot for saving and loading](./docs/save-and-load.avif)
</details>

<details>
	<summary>Can I run it as a service (automatically forward ports at login)?</summary>
Yes. To begin, save a forwarding list by pressing <kbd>⌘</kbd> + <kbd>S</kbd>. Next, open the settings window either from the menu bar or by pressing <kbd>⌘</kbd> + <kbd>,</kbd>. Check the "Launch at login" and "Load configurations at startup" checkboxes. Finally, add a previously saved configuration file (you can add multiple files, but ensure they do not conflict with each other).
</details>

<details>
	<summary>What does the "Too many open files" error mean?</summary>
By default, macOS allows a maximum of 256 files to be opened. This means you can forward up to 256 ports, or fewer if your system already has open files. To bypass this limitation, simply run `ulimit -n 2048` (or replace the number with your desired value) in your terminal.
</details>

<details>
	<summary>What does the "Permission denied" error mean?</summary>
This error usually happens when trying to forward a port to a local port below 1024. In macOS, binding a port less than 1024 to 127.0.0.1 needs root privileges, which iPortForwarder currently does not support. However, strangely enough, macOS doesn't require root privileges for binding ports less than 1024 to 0.0.0.0, so you can easily bypass this limitation by enabling the "Allow LAN" option.
</details>
