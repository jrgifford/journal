# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a LaTeX-based journal/planner generator that creates customizable paper planners. The system generates structured PDFs for personal organization, originally based on the DIY Organizer project by Rurik Christiansen.

## Architecture

The codebase uses a three-stage build process:

1. **Configuration Stage**: `gen_config.py` defines the target year, locale settings, and custom events
2. **Generation Stage**: `gen_Current_Macros.py` reads the configuration and generates LaTeX macro files
3. **Compilation Stage**: LaTeX compilation with pdflatex creates the final PDF

### Key Components

- **Configuration System**: `gen_config.py` sets the target year (currently 2022), locale (en_GB.utf-8), and week start preference (Monday vs Sunday)
- **Event Management**: `gen_events.py` provides a simple event system for adding holidays and special dates to the calendar
- **Macro Generator**: `gen_Current_Macros.py` is the core generator that creates four LaTeX macro files:
  - `DYI_i18n.tex` - Internationalization macros for day/month names
  - `DYI_Month_Tables.tex` - Monthly calendar table macros for current/previous/next years
  - `DYI_Monthly_Planner_Tables.tex` - Monthly planner page macros
  - `DYI_Weekly_Planner_Tables.tex` - Weekly planner page macros

## Build Commands

### Standard Build
```bash
make
```
This runs the complete build process: generates macro files, processes gnuplot charts, and compiles the main PDF.

### Docker Build (Recommended)
```bash
docker build -t journallatex .
./latexdockercmd.sh make
```

### Clean Commands
```bash
make clean      # Remove intermediate files but keep the final PDF
make realclean  # Remove all generated files including the final PDF
```

## Development Workflow

1. **Change Target Year**: Edit the `year` variable in `gen_config.py:7`
2. **Add Events**: Use `events.add_event(year, month, day, "Event Name", is_holiday)` in `gen_config.py`
3. **Modify Locale**: Update locale settings and text strings in `gen_config.py`
4. **Build**: Run `make` to regenerate everything

## Prerequisites

- `texlive-full` (LaTeX distribution)
- `gnuplot` (for chart generation) 
- `ghostscript` (for ps2pdf conversion)

On macOS, use MacTeX and Homebrew, though Docker is recommended for reliability.