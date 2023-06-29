# iPortForwarder

A native macOS app built using SwiftUI, enables you to forward multiple remote ports to your local ports.

## Screenshot

![screenshot](./docs/screenshot.avif)

## Download

Go to the [GitHub Releases](https://github.com/hronro/iPortForwarder/releases) page.

## FAQ

<details><summary>What does the "Too many open files" error mean?</summary>
	By default, macOS allows a maximum of 256 files to be opened. This means you can forward up to 256 ports, or fewer if your system already has open files. To bypass this limitation, simply run `ulimit -n 2048` (or replace the number with your desired value) in your terminal.
</details>

<details><summary>What does the "Permission denied" error mean?</summary>
	This error usually happens when trying to forward a port to a local port below 1024. In macOS, binding a port less than 1024 to 127.0.0.1 needs root privileges, which iPortForwarder currently does not support. However, strangely enough, macOS doesn't require root privileges for binding ports less than 1024 to 0.0.0.0, so you can easily bypass this limitation by enabling the "Allow LAN" option.
</details>
