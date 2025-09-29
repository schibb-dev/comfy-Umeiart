Secrets setup

- Create a `.hf_token` file at the repo root with your Hugging Face token.

- Create a `.civitai_token` file at the repo root with your Civitai API token.
- Do NOT commit `.civitai_token`. It is ignored via `.gitignore`.
- Use `.civitai_token.example` as a template and copy to `.civitai_token`, then fill in your real token.

Access in scripts:
CIVITAI_API_TOKEN=$(jq -r ".civitai_token" .civitai_token)
- Do NOT commit `.hf_token`. It is already ignored via `.gitignore`.
- Use `.hf_token.example` as a template and copy to `.hf_token`, then fill in your real token.

Example:

cp .hf_token.example .hf_token
$EDITOR .hf_token

Consumers should read the token like this (bash):

TOKEN=$(jq -r '.hf_token' .hf_token)
