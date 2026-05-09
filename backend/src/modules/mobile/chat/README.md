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

Note:

- Prisma schema and migrations stay in `backend/prisma/` because Prisma requires
  them there. Everything else related to the chatbot should stay under this
  folder.
