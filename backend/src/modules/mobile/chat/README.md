Chatbot-related code and content live in this module.

Structure:

- `chat.router.ts`: HTTP entrypoint for mobile chat requests.
- `chat.service.ts`: Orchestrates retrieval, prompting, and provider calls.
- `chat.retrieval.ts`: Vector search against `RagChunk`.
- `chat.prompts.ts`: Role-based prompt templates.
- `chat.provider.ts`: LLM and embeddings provider wrapper.
- `chat.types.ts`: Shared request/response and retrieval types.
- `data/raw/`: Source knowledge files for the chatbot (`.md`, `.json`, `.pdf`).
- `data/processed/`: Generated artifacts such as extracted text or chunk dumps.
- `scripts/`: Chat-only scripts such as ingestion or reindexing.

Runtime tuning:

- `CHAT_PRIMARY_PROVIDER=ollama|gemini` chooses the first model provider.
- `CHAT_FALLBACK_PROVIDER=gemini|ollama` chooses the provider used after errors or timeouts.
- `CHAT_PROVIDER_TIMEOUT_MS=25000` caps slow provider calls before trying fallback.
- `OLLAMA_MODEL=qwen3:4b` can be used for local generation, but `OLLAMA_THINK` defaults to off for faster Qwen3 answers.
- `OLLAMA_NUM_PREDICT=320` limits answer length and keeps local generation from rambling.
- `OLLAMA_EMBEDDING_MODEL=mxbai-embed-large` controls retrieval embeddings; changing it requires re-running `npm run chat:ingest`.

Note:

- Prisma schema and migrations stay in `backend/prisma/` because Prisma requires
  them there. Everything else related to the chatbot should stay under this
  folder.
