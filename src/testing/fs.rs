use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};

use crate::domain::error::AppError;
use crate::domain::ports::fs::FsPort;

pub struct FakeFsPort {
    /// maps a file path to its string content
    pub files: RefCell<HashMap<PathBuf, String>>,
    /// set of directory paths
    pub dirs: RefCell<HashSet<PathBuf>>,
    /// tracks method calls for assertions
    pub events: RefCell<Vec<String>>,
}

impl FakeFsPort {
    pub fn new() -> Self {
        Self {
            files: RefCell::new(HashMap::new()),
            dirs: RefCell::new(HashSet::new()),
            events: RefCell::new(Vec::new()),
        }
    }

    pub fn add_file(&self, path: &Path, content: &str) {
        self.files.borrow_mut().insert(path.to_path_buf(), content.to_string());
        if let Some(parent) = path.parent() {
            self.add_dir(parent);
        }
    }

    pub fn add_dir(&self, path: &Path) {
        let mut dirs = self.dirs.borrow_mut();
        let mut current = path;
        while current != Path::new("") && current != Path::new("/") {
            dirs.insert(current.to_path_buf());
            if let Some(parent) = current.parent() {
                current = parent;
            } else {
                break;
            }
        }
        dirs.insert(path.to_path_buf());
    }
}

impl FsPort for FakeFsPort {
    fn exists(&self, path: &Path) -> bool {
        self.events.borrow_mut().push(format!("exists: {}", path.display()));
        self.files.borrow().contains_key(path) || self.dirs.borrow().contains(path)
    }

    fn read_to_string(&self, path: &Path) -> Result<String, AppError> {
        self.events.borrow_mut().push(format!("read_to_string: {}", path.display()));
        self.files.borrow().get(path).cloned().ok_or_else(|| {
            AppError::Io(std::io::Error::new(std::io::ErrorKind::NotFound, "file not found"))
        })
    }

    fn read_dir(&self, path: &Path) -> Result<Vec<PathBuf>, AppError> {
        self.events.borrow_mut().push(format!("read_dir: {}", path.display()));
        if !self.dirs.borrow().contains(path) {
            return Err(AppError::Io(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                "directory not found",
            )));
        }

        let mut entries = Vec::new();
        for file in self.files.borrow().keys() {
            if let Some(parent) = file.parent()
                && parent == path
                && !entries.contains(file)
            {
                entries.push(file.clone());
            }
        }
        for dir in self.dirs.borrow().iter() {
            if let Some(parent) = dir.parent()
                && parent == path
                && !entries.contains(dir)
            {
                entries.push(dir.clone());
            }
        }
        Ok(entries)
    }

    fn write(&self, path: &Path, content: &[u8]) -> Result<(), AppError> {
        self.events.borrow_mut().push(format!("write: {}", path.display()));
        self.files
            .borrow_mut()
            .insert(path.to_path_buf(), String::from_utf8_lossy(content).to_string());
        Ok(())
    }

    fn create_dir_all(&self, path: &Path) -> Result<(), AppError> {
        self.events.borrow_mut().push(format!("create_dir_all: {}", path.display()));
        self.add_dir(path);
        Ok(())
    }

    fn remove_dir_all(&self, path: &Path) -> Result<(), AppError> {
        self.events.borrow_mut().push(format!("remove_dir_all: {}", path.display()));

        let to_remove_dirs: Vec<PathBuf> =
            self.dirs.borrow().iter().filter(|p| p.starts_with(path)).cloned().collect();
        for p in to_remove_dirs {
            self.dirs.borrow_mut().remove(&p);
        }

        let to_remove_files: Vec<PathBuf> =
            self.files.borrow().keys().filter(|p| p.starts_with(path)).cloned().collect();
        for p in to_remove_files {
            self.files.borrow_mut().remove(&p);
        }

        Ok(())
    }

    fn copy(&self, from: &Path, to: &Path) -> Result<u64, AppError> {
        self.events.borrow_mut().push(format!("copy: {} -> {}", from.display(), to.display()));
        let content = {
            self.files.borrow().get(from).cloned().ok_or_else(|| {
                AppError::Io(std::io::Error::new(std::io::ErrorKind::NotFound, "file not found"))
            })?
        };
        self.files.borrow_mut().insert(to.to_path_buf(), content.clone());
        Ok(content.len() as u64)
    }

    fn rename(&self, from: &Path, to: &Path) -> Result<(), AppError> {
        self.events.borrow_mut().push(format!("rename: {} -> {}", from.display(), to.display()));

        let to_rename_dirs: Vec<PathBuf> =
            self.dirs.borrow().iter().filter(|p| p.starts_with(from)).cloned().collect();
        for p in to_rename_dirs {
            self.dirs.borrow_mut().remove(&p);
            let rel = p.strip_prefix(from).unwrap();
            self.dirs.borrow_mut().insert(to.join(rel));
        }

        let to_rename_files: Vec<(PathBuf, String)> = self
            .files
            .borrow()
            .iter()
            .filter(|(p, _)| p.starts_with(from))
            .map(|(p, c)| (p.clone(), c.clone()))
            .collect();

        for (p, content) in to_rename_files {
            self.files.borrow_mut().remove(&p);
            let rel = p.strip_prefix(from).unwrap();
            let new_path = to.join(rel);
            self.files.borrow_mut().insert(new_path.clone(), content);
            if let Some(parent) = new_path.parent() {
                self.add_dir(parent);
            }
        }

        Ok(())
    }

    fn is_dir(&self, path: &Path) -> bool {
        self.dirs.borrow().contains(path)
    }
}
