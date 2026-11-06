const REPOSITORY = path self .

def execute [directory: path, ...arguments: string]: nothing -> string {
    let result = git -C $directory ...$arguments | complete

    if $result.exit_code != 0 {
        error make {
            msg: $"Git failed in ($directory): ($result.stderr | str trim)"
            labels: [
                {
                    text: "Git command failed"
                    span: (metadata $directory).span
                }
            ]
        }
    }

    $result.stdout | str trim
}

def link [target: path, destination: path]: nothing -> nothing {
    let target = $target | path expand --no-symlink
    let destination = $destination | path expand --no-symlink
    let kind = $destination | path type | default missing

    if $kind != missing and $kind != symlink {
        error make {
            msg: $"Refusing to replace a non-link: ($destination)"
            labels: [
                {
                    text: "Destination is not a symbolic link"
                    span: (metadata $destination).span
                }
            ]
        }
    }

    mkdir ($destination | path dirname)

    if $kind == symlink {
        rm $destination
    }

    let result = if $nu.os-info.name == windows {
        if ($target | path type) == dir {
            cmd /c mklink /D $destination $target | complete
        } else {
            cmd /c mklink $destination $target | complete
        }
    } else {
        ln -s $target $destination | complete
    }

    if $result.exit_code != 0 {
        error make {
            msg: $"Could not link ($destination): ($result.stderr | str trim)"
            labels: [
                {
                    text: "Link creation failed"
                    span: (metadata $destination).span
                }
            ]
        }
    }
}

def clean [...worktrees: record<name: string, repository: string, path: string>]: nothing -> nothing {
    for worktree in $worktrees {
        if ($worktree.path | path exists) {
            (execute
                $worktree.repository
                worktree
                remove
                '--force'
                $worktree.path
            ) | ignore
        }
    }
}

def main [
    --agent: path # Agent directory to receive workflow links.
    --prepare-only # Prepare workflow content without changing agent links.
    --update # Refresh upstream pins and adaptation patches before activation.
]: nothing -> record<skills: string, agents: string, commands: string, linked: bool> {
    let destination = if $agent != null {
        $agent | path expand
    } else {
        $env.PI_CODING_AGENT_DIR?
        | default '~/.omp/agent'
        | path expand
    }

    let links = [skills commands agents/poteto.md agents/researcher.md] | each {|name|
        let path = $destination | path join $name
        let kind = $path | path type | default missing

        if $kind != missing and $kind != symlink {
            error make {
                msg: $"Refusing to replace a non-link: ($path)"

                labels: [
                    {
                        text: "Destination is not a symbolic link"
                        span: (metadata $path).span
                    }
                ]
            }
        }

        let previous = if $kind == symlink {
            if not ($path | path exists) {
                error make {
                    msg: $"Refusing to replace a dangling link: ($path)"

                    labels: [
                        {
                            text: "Symbolic link target does not exist"
                            span: (metadata $path).span
                        }
                    ]
                }
            }

            $path | path expand
        } else {
            null
        }

        {name: $name, path: $path, previous: $previous}
    }

    let executable = mise which impeccable | complete

    if $executable.exit_code != 0 {
        error make {
            msg: 'Impeccable is not installed through mise; installation requires approval.'
            labels: [
                {
                    text: "Impeccable executable was not found"
                    span: (metadata $executable).span
                }
            ]
        }
    }

    let engine = $executable.stdout | str trim
    let probe = (^$engine engine-probe | complete)

    if $probe.exit_code != 0 {
        error make {
            msg: $"Impeccable engine probe failed: ($probe.stderr | str trim)"
            labels: [
                {
                    text: "Engine probe failed"
                    span: (metadata $probe).span
                }
            ]
        }
    }

    let version = (
        $probe.stdout
        | str trim
        | parse --regex '^impeccable-engine (?<version>[0-9]+\.[0-9]+\.[0-9]+)$'
        | get version
        | first
    )

    let prepared = $REPOSITORY | path join prepared
    mkdir $prepared
    let stage = (mktemp --directory --tmpdir-path $prepared XXXXXXXX)

    let worktrees = [
        impeccable
        interface
        patterns
        canonical
        pstack
        humanlayer
    ] | each {|name|
        {
            name: $name
            repository: ($REPOSITORY | path join upstream $name)
            path: ($stage | path join upstream $name)
        }
    }

    try {
        for name in [skills agents commands] {
            cp --recursive ($REPOSITORY | path join local $name) ($stage | path join $name)
        }

        for item in $worktrees {
            let name = $item.name
            let source = $item.repository
            let worktree = $item.path

            if not ($source | path join .git | path exists) {
                (execute
                    $REPOSITORY
                    submodule
                    update
                    '--init'
                    '--recursive'
                    '--'
                    $"upstream/($name)"
                )
            }

            if (execute $source status '--porcelain') != '' {
                error make {
                    msg: $"Upstream checkout has local changes: ($source)"
                    labels: [
                        {
                            text: "Upstream checkout must be pristine"
                            span: (metadata $source).span
                        }
                    ]
                }
            }

            let entry = (
                execute $REPOSITORY ls-files '--stage' $"upstream/($name)"
                | split row --regex \s+
            )

            if ($entry | length) != 4 or $entry.0 != '160000' or $entry.2 != '0' {
                error make {
                    msg: $"Missing or unresolved submodule pin: ($name)"
                    labels: [
                        {
                            text: "Submodule pin is unavailable"
                            span: (metadata $name).span
                        }
                    ]
                }
            }

            let revision = if $name == impeccable {
                let release = $"refs/tags/engine-v($version)"
                execute $source fetch origin $release
                execute $source rev-parse FETCH_HEAD
            } else if $update {
                execute $source fetch '--no-tags' origin HEAD
                execute $source rev-parse FETCH_HEAD
            } else {
                execute $source rev-parse HEAD
            }

            execute $source worktree add '--detach' $worktree $revision

            (execute
                $worktree
                apply
                '--index'
                '--3way'
                ($REPOSITORY | path join patches $"($name).patch")
            ) | ignore

            match $name {
                'impeccable' => {
                    let target = $stage | path join skills impeccable
                    cp --recursive ($worktree | path join skill) $target
                    mv ($target | path join SKILL.src.md) ($target | path join SKILL.md)
                }
                'interface' => {
                    let package = $worktree | path join src ui-ux-pro-max
                    let target = $stage | path join skills interface
                    cp --recursive ($package | path join data) ($target | path join data)
                    mkdir ($target | path join scripts) ($target | path join references)

                    for file in (
                        ls ($package | path join scripts)
                        | where type == file
                        | where name =~ \.py$
                        | get name
                    ) {
                        cp $file ($target | path join scripts)
                    }

                    cp ($package | path join templates base skill-content.md) ($target | path join references application.md)
                    cp ($package | path join templates base quick-reference.md) ($target | path join references guide.md)
                }
                'patterns' => {
                    mkdir ($stage | path join skills rust references)
                    cp --recursive ($worktree | path join omp) ($stage | path join skills rust references design)
                }
                'canonical' => {
                    cp --recursive ($worktree | path join omp) ($stage | path join skills rust references canonical)
                }
                'pstack' => {
                    let package = $worktree | path join pstack skills

                    for skill in [
                        architect
                        arena
                        how
                        interrogate
                        swarm
                        tdd
                        typescript
                        unslop
                        why
                        writing
                    ] {
                        let directory = match $skill {
                            typescript => 'typescript-best-practices'
                            writing => 'technical-writing'
                            _ => $skill
                        }

                        cp --recursive ($package | path join $directory) ($stage | path join skills $skill)
                    }

                    let target = $stage | path join skills poteto
                    mkdir ($target | path join playbooks) ($target | path join references principles)
                    cp ($package | path join poteto-mode SKILL.md) ($target | path join SKILL.md)

                    for playbook in [bug-fix feature investigation refactoring] {
                        cp (
                            $package
                            | path join poteto-mode playbooks $"($playbook).md"
                        ) ($target | path join playbooks)
                    }

                    let principles = [
                        [source, destination];
                        [exhaust-the-design-space, alternatives]
                        [never-block-on-the-human, authorization]
                        [build-the-lever, automation]
                        [test-behavior-not-implementation, behavior]
                        [boundary-discipline, boundaries]
                        [fix-root-causes, causes]
                        [guard-the-context-window, context]
                        [model-the-domain, domain]
                        [encode-lessons-in-structure, enforcement]
                        [experience-first, experience]
                        [foundational-thinking, foundations]
                        [make-operations-idempotent, idempotence]
                        [explain-the-number, measurements]
                        [migrate-callers-then-delete-legacy-apis, migration]
                        [outcome-oriented-execution, outcomes]
                        [separate-before-serializing-shared-state, ownership]
                        [attack-the-premise, premise]
                        [minimize-reader-load, readability]
                        [redesign-from-first-principles, redesign]
                        [sequence-verifiable-units, sequencing]
                        [laziness-protocol, simplicity]
                        [subtract-before-you-add, subtraction]
                        [type-system-discipline, types]
                        [prove-it-works, verification]
                    ]

                    for principle in $principles {
                        cp (
                            $package
                            | path join $"principle-($principle.source)" SKILL.md
                        ) (
                            $target
                            | path join references principles $"($principle.destination).md"
                        )
                    }
                }
                'humanlayer' => {
                    for skill in [
                        design-control-loop
                        rpi
                        show-me
                        visual-pr
                    ] {
                        cp --recursive (
                            $worktree
                            | path join plugins $skill skills $skill
                        ) ($stage | path join skills $skill)
                    }
                }
            }
        }

        let version = (
            open --raw ($stage | path join skills impeccable scripts VERSION)
            | str trim
        )

        if $probe.exit_code != 0 or ($probe.stdout | str trim) != $"impeccable-engine ($version)" {
            error make {
                msg: $"Installed Impeccable engine does not match the prepared skill's required version ($version)."
                labels: [
                    {
                        text: "Required engine version"
                        span: (metadata $version).span
                    }
                ]
            }
        }

        if $update {
            for item in $worktrees {
                let revision = execute $item.path rev-parse HEAD
                if $revision != (execute $item.repository rev-parse HEAD) {
                    let patch = $REPOSITORY | path join patches $"($item.name).patch"
                    execute $item.repository checkout '--detach' $revision
                    (execute
                        $item.path
                        diff
                        '--cached'
                        '--binary'
                        '--full-index'
                        $"--output=($patch)"
                    )
                }
            }
        }

        clean ...$worktrees
        rm ($stage | path join upstream)
    } catch {|failure|
        try {
            clean ...$worktrees
            rm --recursive $stage
        } catch {|cleanup| error make {
            msg: $"($failure.msg) Cleanup also failed: ($cleanup.msg)"
            labels: [
                {
                    text: "Preparation cleanup failed"
                    span: (metadata $cleanup).span
                }
            ]
        } }

        error make {
            msg: $failure.msg
            labels: [
                {
                    text: "Preparation failed"
                    span: (metadata $failure).span
                }
            ]
        }
    }

    if not $prepare_only {
        mkdir $destination

        try {
            for entry in $links {
                link ($stage | path join $entry.name) $entry.path
            }
        } catch {|failure|
            for entry in $links {
                if $entry.previous != null {
                    link $entry.previous $entry.path
                } else if ($entry.path | path type) == symlink {
                    rm $entry.path
                }
            }

            error make {
                msg: $failure.msg
                labels: [
                    {
                        text: "Agent linking failed"
                        span: (metadata $failure).span
                    }
                ]
            }
        }
    }

    {
        skills: ($stage | path join skills)
        agents: ($stage | path join agents)
        commands: ($stage | path join commands)
        linked: (not $prepare_only)
    }
}
