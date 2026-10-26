# Release Checklist

This checklist is for a maintainer preparing an approved staging snapshot for the public repository. A green host CI run is necessary, but it does not replace Android device testing.

## Content and metadata

- [ ] The release scope is explicit and contains no unrelated staging work.
- [ ] `VERSION`, the README badge, device compatibility page, and changelog agree.
- [ ] The changelog describes the user-visible changes and uses the approved release date.
- [ ] Documentation claims match the scripts, saved evidence, or a cited upstream source.
- [ ] Public text contains no private paths, device serials, tokens, IP addresses, or operator-only context.

## Host checks

- [ ] Shell syntax and ShellCheck pass.
- [ ] `scripts/check-sync.sh` passes.
- [ ] `scripts/check-metadata.sh` passes.
- [ ] Wrapper, installer, SSRF, and mutation suites pass on Linux.
- [ ] Internal links pass; external-link warnings have been reviewed.

## Device checks

- [ ] The required device modes were run with the exact staged scripts.
- [ ] Every device result is classified as `PASS`, `FAIL`, `SKIP`, or `HARNESS_ERROR`.
- [ ] No required check is `FAIL` or `HARNESS_ERROR`.
- [ ] `SKIP` results are explained and do not hide a release requirement.
- [ ] Saved artifacts have been reviewed for personal data.

## Public release gate

- [ ] The public repository working tree and `main` match the expected public baseline.
- [ ] Commit author and active GitHub account are verified.
- [ ] The backup tag and release tag names are correct.
- [ ] The operator has given explicit approval for this specific public push.
- [ ] The approved main commit and release tag will be pushed atomically.

Do not mark a release ready because a command merely produced output. Review the expected result and the recorded verdict for every required gate.
