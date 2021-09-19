#!/bin/sh
#
# Install pandoc and wkhtmltopdf, if needed.

PANDOC_DEB_URL=${PANDOC_DEB_URL:-"https://github.com/jgm/pandoc/releases/download/2.14.2/pandoc-2.14.2-1-amd64.deb"}
WKHTMLTOPDF_DEB_URL=${WKHTMLTOPDF_DEB_URL:-"https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb"}

err() {
	echo "$*" >&2
}

command_exists() {
	command -v "$1" >/dev/null 2>&1;
}

install_pandoc() {
	if command_exists install-pkg; then
		install-pkg "$PANDOC_DEB_URL"
		return $?
	elif command_exists apt; then
	  apt update && apt install pandoc
		return $?
	else
		err "Unable to detect your package manager."
	fi
}

install_wkhtmltopdf() {
	if command_exists install-pkg; then
		install-pkg "$WKHTMLTOPDF_DEB_URL" \
			&& ln -s "$HOME"/.apt/usr/local/bin/wkhtmltoimage "$HOME"/.apt/usr/bin/wkhtmltoimage \
			&& ln -s "$HOME"/.apt/usr/local/bin/wkhtmltopdf "$HOME"/.apt/usr/bin/wkhtmltopdf \
			&& return 0
	elif command_exists apt; then
		apt update && apt install wkhtmltopdf --no-install-recommends && return 0
	else
		err "Unable to detect your package manager."
	fi
	return 1
}

if ! command_exists pandoc; then
	if ! install_pandoc; then
		err "Failed to install pandoc."
		exit 1
	fi
fi

if ! command_exists wkhtmltopdf; then
	if ! install_wkhtmltopdf; then
		err "Failed to install wkhtmltopdf."
		exit 1
	fi
fi
