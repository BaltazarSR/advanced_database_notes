# Vector Search

## My understanding
Vector search is a way to find similar items by comparing mathematical representations (vectors/embeddings) instead of matching exact values. Each piece of data (text, image, audio) is converted into a high-dimensional vector using a model, and the database finds other vectors that are "close" to a query vector using distance metrics like cosine similarity or Euclidean distance.

Traditional SQL searches for exact or pattern matches (`WHERE name = 'cat'`). Vector search finds semantically similar results — a query for "dog" might return documents about "puppy" or "canine" because their vectors are nearby in the embedding space.

## Why it matters
- Powers semantic search, recommendation systems, and AI-augmented queries
- Enables Retrieval-Augmented Generation (RAG): giving LLMs relevant context from a database before generating a response
- Works on unstructured data (text, images, audio) that relational databases can't index meaningfully
- Scales to millions of vectors with approximate nearest neighbor (ANN) algorithms like HNSW and IVF, which trade a small accuracy loss for massive speed gains

## Key concepts

| Term | Meaning |
|------|---------|
| Embedding | A vector (list of floats) representing the semantic content of data |
| Similarity search | Finding vectors nearest to a query vector |
| Cosine similarity | Measures angle between vectors — 1 = identical direction, 0 = unrelated |
| Euclidean distance | Straight-line distance between two vectors |
| ANN | Approximate Nearest Neighbor — fast but not exact |
| HNSW | Hierarchical Navigable Small World — a popular ANN index structure |

## Example

```sql
-- PostgreSQL with pgvector extension

-- Store embeddings alongside regular columns
CREATE TABLE articles (
  id SERIAL PRIMARY KEY,
  title TEXT,
  body TEXT,
  embedding VECTOR(1536)  -- dimension depends on the model used
);

-- Create an HNSW index for fast ANN search
CREATE INDEX ON articles USING hnsw (embedding vector_cosine_ops);

-- Find the 5 most similar articles to a given query vector
SELECT title, body
FROM articles
ORDER BY embedding <=> '[0.12, 0.45, ..., 0.98]'  -- <=> = cosine distance
LIMIT 5;
```

## Common databases with vector support
- **PostgreSQL** — via `pgvector` extension
- **MongoDB** — Atlas Vector Search
- **Redis** — RediSearch module
- **Pinecone / Weaviate / Qdrant** — purpose-built vector databases

## Related concepts
- [Indexes](./Basics.md)
