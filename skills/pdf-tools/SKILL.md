# PDF Tools Skill

Extract text, tables, and data from PDF documents. Process medical papers, research, and reports.

## Commands

```bash
# Extract text from PDF
pdf-tools extract document.pdf --output text.txt

# Extract tables to CSV
pdf-tools tables document.pdf --output tables.csv

# Extract specific pages
pdf-tools extract document.pdf --pages 1-5 --output summary.txt

# Search within PDF
pdf-tools search document.pdf --query "neurovascular"

# Batch process directory
pdf-tools batch ./pdfs/ --output ./extracted/

# Convert to markdown
pdf-tools convert document.pdf --format markdown
```

## Features

- **Text Extraction:** Full document or specific pages
- **Table Parsing:** Convert tables to CSV/JSON
- **Search:** Find keywords across documents
- **Batch Processing:** Process multiple files
- **OCR Support:** Extract from scanned documents (requires Tesseract)
- **Medical Papers:** Optimized for research PDFs

## Configuration

Config file: `~/.openclaw/skills/pdf-tools/config.json`

```json
{
  "ocr": {
    "enabled": true,
    "language": "eng"
  },
  "output": {
    "format": "markdown",
    "includeMetadata": true
  },
  "batch": {
    "parallel": 4
  }
}
```

## Output

```
PDF Extraction Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: neurovascular-study.pdf
Pages: 24
Text extracted: 15,432 words
Tables found: 3
Images found: 8

Key findings:
- Market size: $12.4B (2026)
- Growth rate: 8.7% CAGR
- Key players: Medtronic, Stryker, Johnson & Johnson

Saved to: ./extracted/neurovascular-study.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```