import '../../ansible.just'

# Configure Git settings only
git:
  @echo "🚀 Running common Git setup..."
  @just _run_ansible "vcs" "common" "git"

# Configure JJ (Jujutsu) settings only
jj:
  @echo "🚀 Running common JJ setup..."
  @just _run_ansible "vcs" "common" "jj"

# Switch to personal VCS configuration
sw-p:
  @echo "🔄 Switching to personal configuration..."
  @git config --global user.name "{{env('PERSONAL_VCS_NAME')}}"
  @git config --global user.email "{{env('PERSONAL_VCS_EMAIL')}}"
  @[ -n "{{env('PERSONAL_VCS_NAME')}}" ] || (echo "PERSONAL_VCS_NAME is empty" >&2; exit 1)
  @[ -n "{{env('PERSONAL_VCS_EMAIL')}}" ] || (echo "PERSONAL_VCS_EMAIL is empty" >&2; exit 1)
  @echo "1" | jj config set --user user.name "{{env('PERSONAL_VCS_NAME')}}"
  @echo "1" | jj config set --user user.email "{{env('PERSONAL_VCS_EMAIL')}}"
  @echo "✅ Switched to personal configuration."
  @echo "Git user: `git config --get user.name` <`git config --get user.email`>"
  @echo "jj  user: `jj config get user.name` <`jj config get user.email`>"

# Switch to work VCS configuration
sw-w:
  @echo "🔄 Switching to work configuration..."
  @git config --global user.name "{{env('WORK_VCS_NAME')}}"
  @git config --global user.email "{{env('WORK_VCS_EMAIL')}}"
  @[ -n "{{env('WORK_VCS_NAME')}}" ] || (echo "WORK_VCS_NAME is empty" >&2; exit 1)
  @[ -n "{{env('WORK_VCS_EMAIL')}}" ] || (echo "WORK_VCS_EMAIL is empty" >&2; exit 1)
  @echo "1" | jj config set --user user.name "{{env('WORK_VCS_NAME')}}"
  @echo "1" | jj config set --user user.email "{{env('WORK_VCS_EMAIL')}}"
  @echo "✅ Switched to work configuration."
  @echo "Git user: `git config --get user.name` <`git config --get user.email`>"
  @echo "jj  user: `jj config get user.name` <`jj config get user.email`>"
