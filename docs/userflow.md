# Little Artist User Flow

This flow is derived from the current SwiftUI implementation.

```mermaid
flowchart TD
  A["App Launch"] --> B{"hasCompletedOnboarding?"}
  B -- "No" --> O["Onboarding (5 pages)"]
  O --> OA{"User action"}
  OA -- "Skip (pages 1-4)" --> H["Home"]
  OA -- "Next" --> O
  OA -- "Get Started (page 5)" --> H
  B -- "Yes" --> H

  H --> C{"Any children?"}
  C -- "No" --> NC["No Children State"]
  NC --> AC["Add Child Sheet"]
  AC --> H

  C -- "Yes" --> S["Select Child"]
  S --> AR{"Any artworks for selected child?"}
  AR -- "No" --> NA["No Artwork State"]
  NA --> AA["Add Artwork Sheet"]
  AA --> AR

  AR -- "Yes" --> G["Artwork Gallery (year/month groups)"]
  G --> D["Artwork Detail"]
  D --> DA{"Detail action"}
  DA -- "Share" --> SH["System Share Sheet"]
  DA -- "Edit" --> ED["Edit Artwork Form"]
  ED --> D
  DA -- "Delete" --> DC["Delete Confirmation"]
  DC --> AR

  AA --> AI{"AI suggestions available?"}
  AI -- "Yes" --> SG["Suggest Title & Caption"]
  SG --> AA
  AI -- "No" --> AA
```

## Notes
- The floating `Add Artwork` button is shown only when a child is selected.
- Gallery items navigate to `Artwork Detail`.
- `Add Child` and `Add Artwork` are modal sheets from `Home`.
