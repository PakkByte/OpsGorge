ArchiveBase: D:\_Archives
MinSizeMB: 100
SkipPaths:
  - D:\UserData\        # confirm in Policy.json
Gates:
  - PR required with 1 approval
  - STATUS: validate (up-to-date)
  - Signed commits
  - Code Owners: @PakkByte
Bootstrap:
  CI_BOOTSTRAP: 1  # set to 0/remove to enforce
