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
            inlineMath: [['$', '$'], ['\\(', '\\)']],
            displayMath: [['$$', '$$'], ['\\[', '\\]']]
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

### 6. Japanese Report with Custom Author Style
This configuration is tailored for a Japanese academic report based on specific formatting requirements.

**Key Features:**
- A4 format with custom margins (Top/Bottom: 20mm, Left/Right: 25mm).
- Differentiates fonts: Gothic for titles/headings and Mincho for the body text.
- **Crucially, it styles the author's name using a dedicated CSS class (`.author`), which requires wrapping the author's name in a `<p class="author">...</p>` tag within the Markdown file for correct right-alignment.**

**Usage:**
Your markdown file should be structured like this:
```markdown
# Title of the Report
<p class="author">Your Name</p>

### 1. First Section
...
```

**Config File (`japanese-report-config.js`):**
```javascript
module.exports = {
  pdf_options: {
    format: 'a4',
    margin: {
      top: '20mm',
      bottom: '20mm',
      left: '25mm',
      right: '25mm'
    },
    printBackground: true,
    displayHeaderFooter: false
  },
  css: `
    /* Body text style */
    body {
      font-family: 'Hiragino Mincho ProN', 'MS Mincho', serif; /* Mincho font */
      font-size: 10.5pt;
      line-height: 1.7; /* Adjusted for approx. 40 lines per page */
    }

    /* Report Title (h1) */
    h1 {
      font-family: 'Hiragino Kaku Gothic ProN', 'MS Gothic', sans-serif; /* Gothic font */
      font-size: 12pt;
      text-align: center;
      margin-bottom: 1em;
    }

    /* Author Info (using a dedicated class) */
    .author {
      font-family: 'Hiragino Kaku Gothic ProN', 'MS Gothic', sans-serif; /* Gothic font */
      font-size: 11pt;
      text-align: right;
      margin-bottom: 2em;
    }

    /* Section Headings (h3, etc.) */
    h3, h4, h5, h6 {
      font-family: 'Hiragino Kaku Gothic ProN', 'MS Gothic', sans-serif; /* Gothic font */
      font-size: 10.5pt;
      page-break-after: avoid;
    }
  `,
  // MathJax settings (optional, can be removed if no equations)
  script: [
    {
      content: `
        window.MathJax = {
          tex: {
            inlineMath: [['$', '$'], ['\\(', '\\)']],
            displayMath: [['$$', '$$'], ['\\[', '\\]']]
          }
        };
      `
    },
    { url: "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js" }
  ]
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
md-pdf-ini
# Edit md2pdf-config.js as needed
md-pdf -c md2pdf-config.js document.md
```

## Special CSS Classes
- `.page-break` - Forces page break after element
- `.pageNumber` - Current page number (header/footer only)
- `.totalPages` - Total page count (header/footer only)

## Issue with Right-Aligning Author Information and Solution

### Problem
Even when specifying `text-align: right` for the `.author` class in the CSS config file, the author information may not be right-aligned.

### Solution
**Using inline styles** is the most reliable approach:

```html
<div style="text-align: right;">Akitora Hayashi</div>
```

Or

```html
<p style="text-align: right;">Akitora Hayashi</p>
```

### Why Inline Styles Work
1. **CSS Priority**: Inline styles (`style="..."`) have the highest priority.
2. **Stronger than !important**: Inline styles override even `!important` declarations in CSS files.
3. **Processing Order**: Inline styles in HTML are processed after external CSS by md-pdf.

### Verified Working Solutions
- `<div style="text-align: right;">Author Name</div>` → ✅ Right-aligned display
- `<p style="text-align: right;">Author Name</p>` → ✅ Right-aligned display
- `<div style="text-align: right;"><strong>Author Name</strong></div>` → ✅ Right-aligned bold display
- CSS config file only → ❌ Often insufficient

### Best Practice
**Always use inline styles** for author information right-alignment. This guarantees consistent results across different PDF generation environments.

### Technical Explanation
The reason inline styles work reliably:
1. **Highest CSS Specificity**: Inline styles have the highest priority in the CSS cascade.
2. **Overrides External CSS**: Even `!important` declarations in external CSS files are overridden.
3. **Processing Order**: HTML inline styles are processed after external CSS by md-pdf.

### Recommended Pattern
```html
<div style="text-align: right;"><strong>Author Name</strong></div>
```