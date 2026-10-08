# Paperless AI

Paperless-ngx's built-in AI features use the shared **llama.cpp** server on the Docker host. Settings are environment variables in `kubernetes/apps/default/paperless/app/helmrelease.yaml`.

| Variable                                        | Value                                                                       |
| ----------------------------------------------- | --------------------------------------------------------------------------- |
| `PAPERLESS_AI_ENABLED`                          | `true`                                                                      |
| `PAPERLESS_AI_LLM_BACKEND`                      | `openai-like`                                                               |
| `PAPERLESS_AI_LLM_ENDPOINT`                     | `http://nas.main.internal:8080/v1`                                          |
| `PAPERLESS_AI_LLM_MODEL`                        | `gemma-4-12b-ha` (the llama.cpp `--alias`)                                  |
| `PAPERLESS_AI_LLM_API_KEY`                      | from the `llamacpp` 1Password item                                          |
| `PAPERLESS_AI_LLM_EMBEDDING_BACKEND` / `_MODEL` | `huggingface` / `sentence-transformers/all-MiniLM-L6-v2` (runs in the pod)  |
| `HF_HOME`                                       | `/data/local/data/huggingface` (keeps the downloaded model across restarts) |

## Rebuilding the index

Run as the `paperless` user, because the NFS share rejects root:

```sh
kubectl -n default exec deploy/paperless -- \
  su -s /bin/sh paperless -c "cd /usr/src/paperless/src && python3 manage.py document_llmindex rebuild"
```

Use `update` instead of `rebuild` for incremental changes.

## Known behaviour

- **First request is slow.** Each web worker imports PyTorch and loads the embedding model on first use (about 25 seconds). Later requests are fast.
- **"Invalid AI configuration" (HTTP 400).** This message wraps any `ValueError`. When the log shows a pydantic error such as `matched_tags.0 Input should be a valid string`, the model returned malformed tool output, not a configuration problem. Paperless makes a second "localisation" call when an output language is set, either `PAPERLESS_AI_LLM_OUTPUT_LANGUAGE` or the user's display language setting. Setting the user's display language to the browser default skips that call.
- The model is shared with Home Assistant (`--parallel 1`), so concurrent requests queue.
