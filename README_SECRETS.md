Secrets setup

- Create a `.hf_token` file at the repo root with your Hugging Face token.
- Do NOT commit `.hf_token`. It is already ignored via `.gitignore`.
- Use `.hf_token.example` as a template and copy to `.hf_token`, then fill in your real token.

Example:

cp .hf_token.example .hf_token
$EDITOR .hf_token

Consumers should read the token like this (bash):

TOKEN=$(jq -r '.hf_token' .hf_token)
