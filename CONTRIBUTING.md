# Contributing

## Development Setup

1. Clone the repository
```bash
git clone https://github.com/nicosalm/blep.nvim.git
cd blep.nvim
```

2. Install dependencies
- Neovim (nightly recommended)
- Make
- Plenary.nvim (for tests)

## Testing

Run tests:
```bash
make test
```

## Code Style

- Use snake_case for functions and variables
- Keep functions under 70 lines
- Add assertions for function arguments and return values
- Document functions with comments
- Use explicit parameter names in function calls

## Pull Requests

1. Create a feature branch
2. Add tests for new functionality
3. Ensure tests pass
4. Update documentation if needed
5. Submit PR with clear description

## Commit Messages

Format:
```
type: description

[optional body]
```

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- test: Tests
- refactor: Code change that neither fixes a bug nor adds a feature
- style: Code style changes

## License

By contributing, you agree that your contributions will be licensed under MIT License.
