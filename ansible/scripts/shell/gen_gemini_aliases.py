#!/usr/bin/env python3
"""Generate Gemini model aliases for shell initialization."""

MODELS = {
    "pr": "gemini-2.5-pro",
    "fl": "gemini-2.5-flash",
    "lt": "gemini-2.5-flash-lite",
    "i": "gemini-2.5-flash-image-preview",
    "il": "gemini-2.5-flash-image-live-preview",
}

OPTIONS = {
    "": "",
    "y": "-y",
    "p": "-p",
    "ap": "-a -p",
    "yp": "-y -p",
    "yap": "-y -a -p",
}


def main():
    for model_key, model_name in MODELS.items():
        for opts_key, opts_value in OPTIONS.items():
            separator = "-" if opts_key else ""
            alias_name = f"gm-{model_key}{separator}{opts_key}"
            print(f'alias {alias_name}="gemini -m {model_name} {opts_value}"')


if __name__ == "__main__":
    main()
