# md-to-pdf Configuration Examples

## Basic Config Structure
```javascript
module.exports = {
  pdf_options: {
    format: 'a4',           // PDF format
    margin: '30mm 20mm',    // CSS-like margin string or object
    printBackground: true,  // Include backgrounds
    displayHeaderFooter: true,
    headerTemplate: '<div>Header content</div>',
    footerTemplate: '<div>Footer content</div>'
  },
  css: 'body { font-family: Arial; }',  // Inline CSS
  stylesheet: ['path/to/style.css'],    // External CSS files
  body_class: ['markdown-body', 'dark'], // CSS classes for body
  highlight_style: 'github',            // Code syntax highlighting
  script: [                             // JavaScript includes
    { url: "https://cdn.example.com/script.js" },
    { content: "console.log('inline script');" }
  ]
};
```

## Format Options
Supported formats: `a0`, `a1`, `a2`, `a3`, `a4`, `a5`, `a6`, `letter`, `legal`, `tabloid`, `ledger`

## Example Configs

### 1. Letter Format (US Standard)
```javascript
// letter-config.js
module.exports = {
  pdf_options: {
    format: 'letter',
    margin: '1in',
    printBackground: true
  },
  css: `
    body { 
      font-family: 'Times New Roman', serif;
      font-size: 12pt;
      line-height: 1.5;
    }
  `
};
```

### 2. A3 Large Format
```javascript
// a3-config.js
module.exports = {
  pdf_options: {
    format: 'a3',
    margin: '20mm',
    landscape: true
  },
  css: `
    body { font-size: 14pt; }
    table { font-size: 12pt; }
  `
};
```

### 3. Report with Headers/Footers
```javascript
// report-config.js
module.exports = {
  pdf_options: {
    format: 'a4',
    margin: { top: '40mm', right: '20mm', bottom: '30mm', left: '20mm' },
    displayHeaderFooter: true,
    headerTemplate: `
      <div style="font-size: 10px; width: 100%; text-align: center; padding: 10px;">
        <strong>Company Report - Confidential</strong>
      </div>
    `,
    footerTemplate: `
      <div style="font-size: 10px; width: 100%; text-align: center; padding: 10px;">
        Page <span class="pageNumber"></span> of <span class="totalPages"></span>
      </div>
    `
  },
  css: `
    body {
      font-family: 'Arial', sans-serif;
      font-size: 11pt;
    }
    .page-break { page-break-after: always; }
  `
};
```

### 4. Academic Paper with MathJax
```javascript
// academic-config.js
module.exports = {
  pdf_options: {
    format: 'a4',
    margin: '25mm'
  },
  css: `
    body {
      font-family: 'Computer Modern', 'Times New Roman', serif;
      font-size: 12pt;
      line-height: 1.6;
    }
    h1, h2, h3 { page-break-after: avoid; }
  `,
  script: [
    {
      content: `
        window.MathJax = {
          tex: {
            inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
            displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']]
          }
        };
      `
    },
    { url: "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js" }
  ]
};
```

### 5. GitHub-style with Syntax Highlighting
```javascript
// github-config.js
module.exports = {
  stylesheet: [
    'https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.2.0/github-markdown-light.min.css'
  ],
  body_class: 'markdown-body',
  highlight_style: 'github',
  pdf_options: {
    format: 'a4',
    margin: '20mm',
    printBackground: true
  },
  css: `
    .markdown-body {
      font-size: 11px;
      max-width: none;
    }
    .markdown-body pre > code {
      white-space: pre-wrap;
    }
  `
};
```

## Usage Examples
```bash
# Default config
md-pdf document.md

# Letter format
md-pdf -c letter-config.js document.md

# A3 landscape
md-pdf -c a3-config.js large-document.md

# Academic paper
md-pdf -c academic-config.js paper.md

# Initialize and customize config in current directory
md2pdf-ini
# Edit md2pdf-config.js as needed
md-pdf -c md2pdf-config.js document.md
```

## Special CSS Classes
- `.page-break` - Forces page break after element
- `.pageNumber` - Current page number (header/footer only)
- `.totalPages` - Total page count (header/footer only)