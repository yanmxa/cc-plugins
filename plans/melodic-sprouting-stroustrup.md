# Knowledge GraphRAG Auto-Deletion Fix Plan

## Problem

**Current behavior:**
- Update mode only creates, never deletes
- "Alice left Google" with `--update` doesn't remove the relation
- "Alice works at Microsoft" doesn't remove old "Alice works at Google"

**Expected behavior:**
```bash
# Explicit deletion detection
"Alice left Google" --update → Delete Alice→Google relation

# Implicit deletion (mutually-exclusive relations)
"Alice is a ML engineer at Microsoft" --update → Delete old works_at, create new one

# Delete mode precision
"Alice is a ML engineer at Microsoft" --delete → Delete only the relation, not entities
```

## Solution: Dual-Operation Extraction

Update mode returns BOTH add and remove operations in one LLM call:

```json
{
  "operations_to_add": {
    "entities": [...],
    "relations": [...]
  },
  "operations_to_remove": {
    "entities": [],
    "relations": [{"source": "Alice", "target": "*", "keywords": "works_at", ...}]
  },
  "reasoning": "New employment implies removing old works_at"
}
```

**Key design points:**
- Wildcard `"target": "*"` means "delete all relations of this type from source"
- Higher confidence threshold for deletions (0.8 vs 0.7)
- Follows "Trust LLM" principle
- No workflow routing changes

## Implementation (6 files)

### 1. State Schema (`src/workflow/knowledge_graphrag/state.py`)

Add new fields to state:
```python
class KnowledgeGraphRAGState(TypedDict):
    # ... existing ...

    # NEW: Auto-deletion fields
    auto_delete_entities: list[ExtractedEntity]
    auto_delete_relations: list[ExtractedRelation]
```

### 2. Extraction Prompt (`src/workflow/knowledge_graphrag/prompts/extraction.md`)

Add auto-deletion detection section:
- Explicit signals: "left", "quit", "no longer", "resigned from"
- Implicit signals: Mutually-exclusive relations (works_at, located_in)
- Use wildcard `"target": "*"` for "delete all of this type"
- Confidence threshold >0.8 for deletions

Add examples:
- "Alice left Google" → remove Alice→Google
- "Alice is a ML engineer at Microsoft" → remove Alice→* (works_at)

### 3. Deletion Prompt (`src/workflow/knowledge_graphrag/prompts/deletion.md`)

Clarify scope:
- Default to deleting RELATIONS, not entities
- "Alice is a ML engineer at Microsoft" → delete only the relation
- "Delete Alice" → delete the entity

### 4. Extract Node (`src/workflow/knowledge_graphrag/nodes/extract.py`)

Add new parser:
```python
def parse_dual_operation_response(response: str) -> Tuple[
    list[ExtractedEntity],    # add entities
    list[ExtractedRelation],  # add relations
    list[ExtractedEntity],    # remove entities
    list[ExtractedRelation],  # remove relations (supports wildcard)
    str                        # reasoning
]:
    # Parse operations_to_add with confidence > 0.7
    # Parse operations_to_remove with confidence > 0.8
    # Handle wildcard target "*"
```

Update `extract_node()` to use new parser in update mode.

### 5. Update Node (`src/workflow/knowledge_graphrag/nodes/update.py`)

Add wildcard expansion:
```python
async def expand_wildcard_relations(
    rag,
    wildcard_relations: list[ExtractedRelation]
) -> list[tuple[str, str]]:
    # Convert (Alice, *, works_at) → [(Alice, Google), (Alice, Microsoft), ...]
    # Query graph, filter by keywords
```

Update `update_node()`:
1. Process auto-deletions FIRST (expand wildcards, delete relations/entities)
2. Then process additions/updates (existing logic)

Add import: `from .delete import delete_entity, delete_relation`

### 6. Builder (`src/workflow/knowledge_graphrag/builder.py`)

Add to initial_state:
```python
"auto_delete_entities": [],
"auto_delete_relations": [],
```

## Testing

```bash
rm -rf ./data/knowledge_graphrag/

# Test 1: Create
python cli/knowledge_graphrag.py "Alice is a ML engineer at Google" --update
python cli/knowledge_graphrag.py "Alice's job"  # → Google

# Test 2: Explicit deletion
python cli/knowledge_graphrag.py "Alice left Google" --update
python cli/knowledge_graphrag.py "Alice's job"  # → No info

# Test 3: Implicit deletion
python cli/knowledge_graphrag.py "Alice is a ML engineer at Microsoft" --update
python cli/knowledge_graphrag.py "Alice is a ML engineer at Google" --update
python cli/knowledge_graphrag.py "Alice's job"  # → Google (Microsoft removed)

# Test 4: Delete mode
python cli/knowledge_graphrag.py "Alice is a ML engineer at Google" --delete
python cli/knowledge_graphrag.py "Alice's job"  # → No info (relation deleted)
```

## Critical Files (in order)

1. `src/workflow/knowledge_graphrag/state.py`
2. `src/workflow/knowledge_graphrag/prompts/extraction.md`
3. `src/workflow/knowledge_graphrag/prompts/deletion.md`
4. `src/workflow/knowledge_graphrag/nodes/extract.py`
5. `src/workflow/knowledge_graphrag/nodes/update.py`
6. `src/workflow/knowledge_graphrag/builder.py`
