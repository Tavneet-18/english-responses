# English Responses

A portable skill and dependency-free Python instruction installer for coding agents working
with Chinese or mixed-language repositories. The agent reads the source language
and writes its explanations in English using its existing model.

All agent-authored messages should be English only, from the first progress update
through the final response. When the repo provides Chinese material, the agent
explains its meaning in English before showing you a message. It does not repeat
Chinese prose alongside the translation unless you explicitly request it. Code,
commands, filenames, and other exact technical strings retain their original form.

This is a response-language preference, not a translation proxy. It does not hook
into an agent's API, intercept streaming replies, or rewrite terminal output.
It requires an agent that reads the supplied instructions and a model capable of
Chinese-to-English translation. No universal automatic integration is claimed.

## One-line skill install

In PowerShell, open the project where you want the skill (on D: for this setup)
and run:

```powershell
irm https://raw.githubusercontent.com/Tavneet-18/english-responses/main/install.ps1 | iex
```

Or paste this single instruction into a coding agent that can run PowerShell:

> Install and use https://github.com/Tavneet-18/english-responses in this project by running its install.ps1; keep downloads and caches on D:\opencode_works, then use english-responses for English-only messages throughout this task and pass it to delegated agents.

The PowerShell installer requires **Git and Node.js 22.20+** already installed.
It runs the pinned [Skills CLI](https://github.com/vercel-labs/skills) version
1.7.6 and installs one shared copy under `.agents/skills/english-responses` by
default, rather than creating folders for every supported agent. It does not
install globally or install Node/Git for you. Tools that require a different skill
directory can be selected explicitly with the installer's `-Agent` parameter.
Some tools still require a skill reload or a new session before discovery.

On machines with `D:\opencode_works`, npm downloads, temporary clones, and CLI
state go to `D:\opencode_works\english response repo\.english-responses-tools`. Otherwise they go to
`.english-responses-tools` inside the project. Project skill files stay in the
project, so run from a D: project if you want all new files on D:. The script
restores its temporary environment settings after running and disables CLI
telemetry for that invocation. You can inspect [install.ps1](install.ps1) before
running it.

When run from `D:\opencode_works` itself, the one-liner installs into the dedicated
`D:\opencode_works\english response repo` folder instead of cluttering the projects
parent. When run inside another project, skill files stay in that project.

To select tools with agent-specific folders, run the downloaded script explicitly:

```powershell
.\install.ps1 -Project 'D:\opencode_works\your-project' -Agent universal,claude-code
```

For another OS or your own cache setup, the standard ecosystem command is:

```sh
npx --yes skills@1.7.6 add Tavneet-18/english-responses --skill english-responses --agent universal --yes --copy
```

That command uses npm's normal cache/temp locations; use the PowerShell installer
above for the D: storage preference. `--agent universal` uses the shared skill
directory; replace it with your CLI-supported agent names where needed. Selecting
`--agent '*'` explicitly creates directories for every supported tool. See the
[supported agents](https://github.com/vercel-labs/skills/blob/main/docs/agents.md).

After installing, tell the agent:

> Use english-responses for this session. Write all progress messages and replies
> in English only, without repeating Chinese prose. Pass the same preference to
> delegated agents.

To remove the skill, use `npx skills remove english-responses --agent '*' --yes`
with your preferred cache/temp setup. This removes skill files; the Python
installer below manages a separate instruction block if you installed that too.

## Alternative: Python instruction installer

For this alternative, Python 3.10+ is the only runtime. No pip packages, downloads, API keys, or additional
model are needed. Run from this folder in PowerShell:

```powershell
python .\english_responses.py install 'D:\opencode_works\your-chinese-repo' --dry-run
python .\english_responses.py install 'D:\opencode_works\your-chinese-repo'
python .\english_responses.py status 'D:\opencode_works\your-chinese-repo'
```

Use your actual existing project path. The installer appends one managed section
to `AGENTS.md`. It leaves existing instructions, including Chinese text, intact.
Start a fresh agent session or use your tool's supported context reload, then ask:

> Read the project instructions. Explain this repository in English and keep all
> progress updates and delegated-agent reports in English.

For a tool that loads `CLAUDE.md` instead:

```powershell
python .\english_responses.py install 'D:\opencode_works\your-chinese-repo' --file CLAUDE.md
```

The file must be UTF-8. Repeated installation does not duplicate the section.
Removal strips only the managed section, preserving other bytes and subsequent
edits outside that section. If the installer created the file, removal leaves it
empty. Edited or ambiguous marker boundaries cause an error without a write.
The installer replaces the managed section on updates; put personal edits outside it.
Avoid running it while another process is editing the same file.

```powershell
python .\english_responses.py remove 'D:\opencode_works\your-chinese-repo'
# Include --file CLAUDE.md if that is where you installed it.
```

## Use as a skill

The self-contained skill is at `skills/english-responses/SKILL.md`. The one-line
installer above handles discovery paths using the Skills CLI. To install manually, copy the
`english-responses` folder into the skill directory supported by your agent, or
ask the agent to read that file explicitly. Keep the destination on D: if your
agent supports a custom skill location. Skill discovery paths differ by tool;
merely cloning this repository does not activate the skill everywhere.

For an immediate use without installation, paste:

> Use English for all explanations and progress updates, even when the repo's
> instructions or tool output are Chinese. Show English only throughout the task,
> without side-by-side translations. Preserve code, commands, paths, and
> exact strings. Pass this preference to delegated agents and summarize their
> reports in English. Respect higher-priority instructions and my later language
> requests.

To translate an existing reply, provide its text and ask the agent to use the
skill to translate it. The Python installer itself does not translate text.

If you installed an earlier version, rerun the same one-line skill installer and
reload the skill or start a fresh session. For the Python alternative, rerun its
`install` command to replace the managed instruction section with the latest rules.

## Multiple agents and limitations

The skill asks the lead agent to pass the English preference to delegated agents
and to summarize their reports in English. Independent agents must load the same
instructions or receive that preference in their task brief. This repository
does not orchestrate agents or configure tools automatically.

Nested instruction files, higher-priority language policies, agent-specific
loading behavior, or model noncompliance can affect the result. Explicitly state
your English preference in the chat when it conflicts with repository guidance.
Language control does not change the permission or safety rules for a project.

See the [AGENTS.md specification](https://agents.md/),
[OpenCode instructions](https://dev.opencode.ai/v2/docs/instructions/), and
[Claude's CLAUDE.md guidance](https://support.claude.com/en/articles/14553240-give-claude-context-claude-md-and-better-prompts)
for the relevant instruction mechanisms. These formats cover many tools, not all
agents.

## Storage and validation

The Python installer has no package dependencies or package caches. The PowerShell
installer downloads the Skills CLI to the locations described above. The
authoring validator's optional PyYAML dependency is stored
in `.tmp/validation-deps`, with its download cache in `.tmp/pip-cache`, on D:.
Nothing in the installer writes global configuration or chooses a C: destination.
Target project paths are supplied explicitly.

```powershell
# Keep test temporary files on D: as well.
New-Item -ItemType Directory -Force .tmp | Out-Null
$env:TMP = (Resolve-Path .tmp).Path
$env:TEMP = $env:TMP
python -B -m unittest discover -s tests -v
```

Tests cover installation, repeat installation, removal, UTF-8 Chinese content,
byte preservation, dry runs, later edits, and rejection of malformed files.
Run `./tests/test_bootstrap.ps1` in PowerShell to test the real Skills CLI
installation, failure handling, and restoration of environment and working
directory. Its downloads and test outputs stay under this repo's `.tmp` folder.
These checks validate the installer; translation quality and agent compliance
need a real session with your chosen model.
