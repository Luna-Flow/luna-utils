# Contribution guidelines

## Code style

- The project follows the formatting style enforced by the MoonBit toolchain. Format your code automatically with the following command:

  ```bash
  moon fmt
  ```

  Run `moon fmt` before committing your code to keep the style consistent.

  Alternatively, you can use the `ready_to_pr.sh` script to format the code, run checks, generate test coverage files, and create `.mbti` files.

## Naming conventions

### Variable naming

- Use **lowercase letters with underscores** as separators (e.g., `my_var`).
- Variable names should be descriptive and clearly indicate their purpose.

### Function naming

- Use **lowercase letters with underscores** as separators (e.g., `calc_total_price()`).
- Function names should be concise and descriptive, clearly expressing their functionality.

### Struct and trait naming

- Use **PascalCase** (e.g., `MyStruct`, `MyTrait`).
- Names should intuitively reflect the function or role of the struct or trait, avoiding overly abstract or non-descriptive names.

### Constant naming

- **Note:** In MoonBit, "variables" are usually called "bindings" and are immutable by default unless marked with `mut`. Thus, there is no strict distinction between constant and variable naming.
- Use **lowercase letters with underscores** as separators (e.g., `machine_dbl_epsilon`).
- Prefix constants with a descriptive category where applicable (e.g., `machine_dbl_epsilon`, where `machine` indicates a machine-related constant).
- Constant names should be concise and descriptive to facilitate understanding.

### Result error constructors and error codes

- Use **uppercase letters with underscores** as separators (e.g., `E_MAX_ITER`).
- Error codes should be prefixed with `E` to indicate an error-related construct.
- Error codes should be concise and descriptive for easy comprehension.

## Comments

- **Conciseness**: Comments should be clear and to the point, avoiding unnecessary verbosity.
- **Consistency**: Use uniform terminology and style across the codebase.
- **Clarity**: Ensure comments are easy to understand, avoiding complex jargon or ambiguous wording.
- **Accuracy**: Comments must accurately reflect the functionality and purpose of the code.
- **Up-to-date**: Comments should be updated alongside code changes to maintain relevance.

Developers are encouraged to use the AI-generated code comments of the MoonBit LSP to improve efficiency, but AI-generated comments should be reviewed to ensure correctness.

## File standards

### Folder naming

- Use **lowercase letters** for folder names.
- Folder names should be concise, descriptive, and separated using underscores (`_`). Avoid numbers and special characters. For example, use `diff` for differentiation-related functionality and `deriv` for derivative-related functionality.

### File organization

- Files should be organized based on functionality, with each file focusing on a specific feature. Use **lowercase letters with underscores** for file names.
- File names should be descriptive and clearly indicate the core functionality they implement. For example, `gauss_kronrod.mbt` implements Gaussian quadrature with Kronrod extension, and `adaptive_quadrature_gk.mbt` implements adaptive quadrature using Gaussian quadrature with Kronrod extension.
- **Note:** Avoid overly generic or vague file names such as `utils.mbt`. Instead, ensure file names correspond to their function or module.

## Commit guidelines

### Commit messages

- Use the `ready_to_pr.sh` script before committing to format code, run checks, generate test coverage files, and create `.mbti` files.
- Each commit should have a clear description of the changes made.
- Commit messages should be in **English**, concise, and precise.
- Use prefixes such as `fix:`, `feat:`, `refactor:`, and `doc:` to indicate the type of change.

```text
fix: fix bug in something
feat: add feature for something
refactor: refactor something
doc: add docs for something
```

### Commit frequency

- Keep commits small and focused on a single feature or fix.
- Avoid large, monolithic commits that include multiple unrelated changes.

## Code review

- If you are not a maintainer or collaborator, contact them before modifying dependencies or version numbers in `moon.mod.json`.
- All code submissions must undergo **code review**.
- Code reviews should focus on code quality, style, performance, and security.
- Reviewers should provide constructive feedback to improve the code.
