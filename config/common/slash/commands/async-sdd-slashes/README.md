# async-sdd-slashes

This project provides a framework for developing a collection of CLI commands inspired by tools like Codex CLI, Claude CLI, and Gemini CLI, using the Specification-Driven Development (SDD) process.

## Overview

The SDD process is structured around specialized roles, each contributing to a phase of development. This ensures transparency, thorough analysis, and systematic implementation.

## SDD Files

- **sdd-0-act.md**: IT Consultant - Sets up the thinking mindset for SDD, emphasizing logging and active problem-solving.
- **sdd-1-rq.md**: Business Analyst - Extracts and defines requirements from discussion logs into a clear document.
- **sdd-2-d.md**: Software Architect - Outlines the solution architecture and implementation plan.
- **sdd-3-td.md**: QA Engineer - Plans testing strategies and coverage.
- **sdd-4-tk.md**: Engineering Manager - Breaks down tasks into phases and assigns agents.
- **sdd-5-pm.md**: Prompt Engineer - Creates activation prompts for agents based on tasks.
- **sdd-6-dc.md**: Document Manager - Recommends documentation integration and updates.

## Usage

Follow the SDD process by activating each role in sequence, using the `.tmp/` directory for intermediate artifacts like `minutes.md`, `requirements.md`, etc. This framework helps build robust CLI tools through structured development.
