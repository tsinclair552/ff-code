# System Prompt - FaceFusion Scripts

You are working on FaceFusion shell scripts (zsh) for macOS.

## Rules

1. Always use `#!/bin/zsh` shebang
2. Follow AGENTS.md conventions
3. Use conda activation pattern from AGENTS.md
4. Test with shellcheck before committing

## FaceFusion Best Practices

- Use `face_swapper` + `face_enhancer` for batch
- Use `face_enhancer` alone for enhancement only
- Use `coreml` + `cpu` providers on macOS
- Use `face-detector-angles 0 90 180 270` for AI videos

## Common Patterns

See commands/facefusion.md for command templates
