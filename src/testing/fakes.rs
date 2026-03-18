use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;
use crate::domain::ports::fs::FsPort;

pub struct FakeFsPort {
    // files maps a file path to its string content
    pub files: Mutex<HashMap<PathBuf, String>>,
    // dirs is a set of directory paths
    pub dirs: Mutex<HashSet<PathBuf>>,
    // events tracks method calls for assertions
    pub events: Mutex<Vec<String>>,
}

impl FakeFsPort {
    pub fn new() -> Self {
        Self {
            files: Mutex::new(HashMap::new()),
            dirs: Mutex::new(HashSet::new()),
            events: Mutex::new(Vec::new()),
        }
    }

    pub fn add_file(&self, path: &Path, content: &str) {
        self.files.lock().unwrap().insert(path.to_path_buf(), content.to_string());
        if let Some(parent) = path.parent() {
            self.add_dir(parent);
        }
    }

    pub fn add_dir(&self, path: &Path) {
        let mut dirs = self.dirs.lock().unwrap();
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
        self.events.lock().unwrap().push(format!("exists: {}", path.display()));
        self.files.lock().unwrap().contains_key(path) || self.dirs.lock().unwrap().contains(path)
    }

    fn read_to_string(&self, path: &Path) -> Result<String, AppError> {
        self.events.lock().unwrap().push(format!("read_to_string: {}", path.display()));
        self.files.lock().unwrap().get(path).cloned().ok_or_else(|| {
            AppError::Io(std::io::Error::new(std::io::ErrorKind::NotFound, "file not found"))
        })
    }

    fn read_dir(&self, path: &Path) -> Result<Vec<PathBuf>, AppError> {
        self.events.lock().unwrap().push(format!("read_dir: {}", path.display()));
        if !self.dirs.lock().unwrap().contains(path) {
            return Err(AppError::Io(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                "directory not found",
            )));
        }

        let mut entries = Vec::new();
        for file in self.files.lock().unwrap().keys() {
            if let Some(parent) = file.parent()
                && parent == path
                && !entries.contains(file)
            {
                entries.push(file.clone());
            }
        }
        for dir in self.dirs.lock().unwrap().iter() {
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
        self.events.lock().unwrap().push(format!("write: {}", path.display()));
        self.files
            .lock()
            .unwrap()
            .insert(path.to_path_buf(), String::from_utf8_lossy(content).to_string());
        Ok(())
    }

    fn create_dir_all(&self, path: &Path) -> Result<(), AppError> {
        self.events.lock().unwrap().push(format!("create_dir_all: {}", path.display()));
        self.add_dir(path);
        Ok(())
    }

    fn remove_dir_all(&self, path: &Path) -> Result<(), AppError> {
        self.events.lock().unwrap().push(format!("remove_dir_all: {}", path.display()));
        let mut dirs = self.dirs.lock().unwrap();
        let mut files = self.files.lock().unwrap();

        let to_remove_dirs: Vec<PathBuf> =
            dirs.iter().filter(|p| p.starts_with(path)).cloned().collect();
        for p in to_remove_dirs {
            dirs.remove(&p);
        }

        let to_remove_files: Vec<PathBuf> =
            files.keys().filter(|p| p.starts_with(path)).cloned().collect();
        for p in to_remove_files {
            files.remove(&p);
        }

        Ok(())
    }

    fn copy(&self, from: &Path, to: &Path) -> Result<u64, AppError> {
        self.events.lock().unwrap().push(format!("copy: {} -> {}", from.display(), to.display()));
        let content = {
            self.files.lock().unwrap().get(from).cloned().ok_or_else(|| {
                AppError::Io(std::io::Error::new(std::io::ErrorKind::NotFound, "file not found"))
            })?
        };
        self.files.lock().unwrap().insert(to.to_path_buf(), content.clone());
        Ok(content.len() as u64)
    }

    fn rename(&self, from: &Path, to: &Path) -> Result<(), AppError> {
        self.events.lock().unwrap().push(format!("rename: {} -> {}", from.display(), to.display()));
        let mut dirs = self.dirs.lock().unwrap();
        let mut files = self.files.lock().unwrap();

        let to_rename_dirs: Vec<PathBuf> =
            dirs.iter().filter(|p| p.starts_with(from)).cloned().collect();
        for p in to_rename_dirs {
            dirs.remove(&p);
            let rel = p.strip_prefix(from).unwrap();
            dirs.insert(to.join(rel));
        }

        let to_rename_files: Vec<(PathBuf, String)> = files
            .iter()
            .filter(|(p, _)| p.starts_with(from))
            .map(|(p, c)| (p.clone(), c.clone()))
            .collect();
        for (p, content) in to_rename_files {
            files.remove(&p);
            let rel = p.strip_prefix(from).unwrap();
            files.insert(to.join(rel), content);
            if let Some(parent) = to.join(rel).parent() {
                let mut current = parent;
                while current != Path::new("") && current != Path::new("/") {
                    dirs.insert(current.to_path_buf());
                    if let Some(p) = current.parent() {
                        current = p;
                    } else {
                        break;
                    }
                }
                dirs.insert(parent.to_path_buf());
            }
        }

        Ok(())
    }

    fn is_dir(&self, path: &Path) -> bool {
        self.dirs.lock().unwrap().contains(path)
    }
}

pub struct FakeAnsiblePort {
    pub roles_with_config: Vec<String>,
    pub tag_to_role: HashMap<String, String>,
    pub roles_config_dir: HashMap<String, PathBuf>,
    pub all_tags: Vec<String>,
    pub tags_by_role: HashMap<String, Vec<String>>,
    pub events: Mutex<Vec<String>>,
}

impl FakeAnsiblePort {
    pub fn new() -> Self {
        Self {
            roles_with_config: Vec::new(),
            tag_to_role: HashMap::new(),
            roles_config_dir: HashMap::new(),
            all_tags: Vec::new(),
            tags_by_role: HashMap::new(),
            events: Mutex::new(Vec::new()),
        }
    }
}

impl AnsiblePort for FakeAnsiblePort {
    fn run_playbook(&self, profile: &str, tags: &[String], _verbose: bool) -> Result<(), AppError> {
        self.events.lock().unwrap().push(format!("run_playbook: {} with tags {:?}", profile, tags));
        Ok(())
    }

    fn roles_with_config(&self) -> Result<Vec<String>, AppError> {
        Ok(self.roles_with_config.clone())
    }

    fn all_tags(&self) -> Vec<String> {
        self.all_tags.clone()
    }

    fn tags_by_role(&self) -> &HashMap<String, Vec<String>> {
        &self.tags_by_role
    }

    fn role_for_tag(&self, tag: &str) -> Option<&str> {
        self.tag_to_role.get(tag).map(|s| s.as_str())
    }

    fn validate_tags(&self, tags: &[String]) -> bool {
        tags.iter().all(|t| self.all_tags.contains(t))
    }

    fn role_config_dir(&self, role: &str) -> Option<PathBuf> {
        self.roles_config_dir.get(role).cloned()
    }
}
