//! Build the intermediate AGENTS.md by concatenating enabled sections in catalog order.

use std::path::Path;

use crate::coder::catalog;
use crate::error::AppError;
use crate::host_fs::fs::FsPort;

/// Title that precedes the concatenated sections, matching the original AGENTS.md.
const TITLE: &str = "# Rules";

/// Concatenate the enabled sections from `source_dir` into `output_path`.
///
/// `enabled` is in catalog order. Each entry's `<name>.md` body is read verbatim
/// (headings included) and joined with a blank line; the file opens with the title.
pub fn build(
    fs: &dyn FsPort,
    source_dir: &Path,
    enabled: &[String],
    output_path: &Path,
) -> Result<(), AppError> {
    let mut document = String::from(TITLE);
    document.push_str("\n\n");

    for name in enabled {
        let section_path = catalog::section_file(source_dir, name);
        let body = fs.read_to_string(&section_path).map_err(|e| {
            AppError::Config(format!("failed to read section '{}': {e}", section_path.display()))
        })?;
        document.push_str(body.trim_end());
        document.push_str("\n\n");
    }

    if let Some(parent) = output_path.parent() {
        fs.create_dir_all(parent)?;
    }
    fs.write(output_path, document.as_bytes())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::host_fs::FakeFsPort;
    use std::path::PathBuf;

    #[test]
    fn concatenates_in_given_order_under_title() {
        let fs = FakeFsPort::new();
        let source = PathBuf::from("/src/agents-sections");
        fs.add_file(&source.join("design.md"), "### Design\n\n- a\n");
        fs.add_file(&source.join("safety.md"), "### Safety\n\n- b\n");
        let output = PathBuf::from("/cfg/AGENTS.md");

        build(&fs, &source, &["design".to_string(), "safety".to_string()], &output).unwrap();

        let written = fs.files.borrow().get(&output).cloned().unwrap();
        assert_eq!(written, "# Rules\n\n### Design\n\n- a\n\n### Safety\n\n- b\n\n");
    }

    #[test]
    fn excludes_disabled_sections() {
        let fs = FakeFsPort::new();
        let source = PathBuf::from("/src/agents-sections");
        fs.add_file(&source.join("design.md"), "### Design\n\n- a\n");
        fs.add_file(&source.join("testing.md"), "### Testing\n\n- t\n");
        let output = PathBuf::from("/cfg/AGENTS.md");

        build(&fs, &source, &["design".to_string()], &output).unwrap();

        let written = fs.files.borrow().get(&output).cloned().unwrap();
        assert!(!written.contains("Testing"));
    }
}
