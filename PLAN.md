# LaTeX Journal 2025 Dockerization Plan

## Overview
Modernize the LaTeX-based journal generator to work with podman and generate calendars for 2025.

## Analysis Summary
- Current setup uses Ubuntu 16.04 (xenial) - severely outdated
- Uses `docker` commands, needs podman compatibility
- Currently configured for year 2022, needs update to 2025
- Python dependencies may need updates

## Checklist

### Phase 1: Configuration Updates
- [ ] Update target year from 2022 to 2025 in gen_config.py:7
- [ ] Review and update event definitions for 2025
- [ ] Test configuration generation for 2025

### Phase 2: Docker/Podman Modernization
- [ ] Update Dockerfile from Ubuntu 16.04 to modern LTS (22.04 or 24.04)
- [ ] Update package installations for modern Ubuntu
- [ ] Ensure Python 3 compatibility (current uses python-pygments)
- [ ] Test container build with podman

### Phase 3: Build Script Updates
- [ ] Update latexdockercmd.sh to use podman instead of docker
- [ ] Rename script to latexpodmancmd.sh for clarity
- [ ] Update any docker references in documentation
- [ ] Test build process end-to-end

### Phase 4: Testing & Validation
- [ ] Build container image with podman
- [ ] Run macro generation for 2025
- [ ] Compile LaTeX to PDF
- [ ] Verify PDF output quality and correctness
- [ ] Test clean commands work properly

### Phase 5: Documentation
- [ ] Update CLAUDE.md with new podman instructions
- [ ] Update any README references to reflect podman usage
- [ ] Document any breaking changes or new requirements

## Success Criteria
- Container builds successfully with podman
- 2025 journal PDF generates without errors
- All make targets work correctly
- Documentation reflects current setup